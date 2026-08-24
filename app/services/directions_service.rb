require 'net/http'
require 'json'

# Google Directions API を叩いて、2 スポット間の「経路距離・所要時間」を求める。
#
# 失敗時（API キー未設定 / 座標欠落 / API エラー / タイムアウト）は nil を返す。
# 呼び出し側は nil を受けたら直線距離フォールバックに任せ、ルート取得自体は
# 失敗させない方針（#153）。
class DirectionsService
  ENDPOINT = 'https://maps.googleapis.com/maps/api/directions/json'.freeze
  OPEN_TIMEOUT = 5
  READ_TIMEOUT = 5

  # route_spots.transport(enum) → Google Directions の mode / transit_mode。
  TRANSPORT_MODES = {
    'walk' => { mode: 'walking' },
    'car' => { mode: 'driving' },
    'train' => { mode: 'transit', transit_mode: 'rail' },
    'bus' => { mode: 'transit', transit_mode: 'bus' }
  }.freeze
  # transport 未設定（nil）や未知の値は徒歩扱い。
  DEFAULT_MODE = { mode: 'walking' }.freeze

  # transit（電車・バス）は departure_time 未指定だと Google 側が「今」を出発時刻に
  # 使う。深夜など運行時間外に「今」で問い合わせると ZERO_RESULTS になりやすいため、
  # サービス時間外は翌朝の妥当な時間帯まで繰り上げて問い合わせる。
  TRANSIT_SERVICE_START_HOUR = 6
  TRANSIT_SERVICE_END_HOUR = 23
  TRANSIT_FALLBACK_DEPARTURE_HOUR = 9

  # 再試行してよいのは「今の時刻がその路線の運行時間外だっただけ」の可能性がある
  # ZERO_RESULTS のみ。ネットワーク障害や REQUEST_DENIED 等の恒久的なエラーまで
  # 再試行すると、ルート作成/更新のたびに leg ごとのタイムアウトが倍になりうる。
  TRANSIT_RETRYABLE_STATUSES = %w[ZERO_RESULTS].freeze

  # train/bus は transit_mode で rail/bus に絞って問い合わせているが、隣接スポット同士の
  # ような短距離区間だと「その手段限定の直通ルート」が無く ZERO_RESULTS になることがある
  # （例: 最寄り駅まで遠く、実際には別の乗り物を挟まないと乗換案内が成立しない）。
  # 出発時刻を変えても解決しないため、最終フォールバックとして手段を絞らない一般的な
  # transit（乗換案内）で 1 度だけ再試行する。
  RELAXED_TRANSIT_MODE_PARAMS = { mode: 'transit' }.freeze

  # このメートル未満の区間は徒歩を優先する（乗換案内を問い合わせない）。
  # ごく短い区間は乗換の待ち時間・徒歩区間を考えると公共交通機関が実用的でない上、
  # Google 側も短距離の transit 問い合わせに ZERO_RESULTS を返しやすいため。
  AUTO_WALK_THRESHOLD_METERS = 1000

  Attempt = Struct.new(:result, :retryable)
  private_constant :Attempt

  class << self
    # origin / destination は latitude / longitude を持つオブジェクト（Greentea / Temple）。
    # mode は route_spots.transport の文字列（"walk" / "train" など、nil 可）。
    # 返り値: { distance_meters: Integer, duration_seconds: Integer, polyline: String or nil } または nil。
    def leg(origin:, destination:, mode: nil)
      return nil if api_key.blank?
      return nil unless coordinates?(origin) && coordinates?(destination)
      return fetch_leg(origin, destination, mode, nil).result unless transit?(mode)

      transit_leg(origin, destination, mode)
    end

    # ユーザーに手段を選ばせず、区間ごとに最適な移動手段を自動決定する版。
    # 近距離（AUTO_WALK_THRESHOLD_METERS 未満）は徒歩、それ以外は手段を絞らない
    # 一般的な transit（乗換案内）を優先し、見つからなければ徒歩にフォールバックする。
    # 返り値: leg の結果に transport: "walk" | "transit" を加えたもの、または nil。
    def auto_leg(origin:, destination:)
      return nil if api_key.blank?
      return nil unless coordinates?(origin) && coordinates?(destination)

      return walk_leg(origin, destination) if short_distance?(origin, destination)

      relaxed_transit_leg(origin, destination)&.merge(transport: 'transit') || walk_leg(origin, destination)
    end

    private

    def walk_leg(origin, destination)
      fetch_leg(origin, destination, 'walk', nil).result&.merge(transport: 'walk')
    end

    def short_distance?(origin, destination)
      from = Geokit::LatLng.new(origin.latitude, origin.longitude)
      to = Geokit::LatLng.new(destination.latitude, destination.longitude)
      (from.distance_to(to, units: :kms) * 1000) < AUTO_WALK_THRESHOLD_METERS
    end

    # 手段を絞らない一般的な transit（乗換案内）で問い合わせる。サービス時間外の
    # 始発待ちで ZERO_RESULTS になるケースのみ、翌日の妥当な時間帯で 1 度再試行する
    # （transit_leg のロジックと同様。手段の絞り込みが無いのでこれ以上のフォール
    # バックは不要）。
    def relaxed_transit_leg(origin, destination)
      departure = departure_time
      attempt = fetch_leg(origin, destination, nil, departure, mode_params_override: RELAXED_TRANSIT_MODE_PARAMS)

      if attempt.retryable
        retry_departure = retry_departure_time
        if retry_departure != departure
          attempt = fetch_leg(origin, destination, nil, retry_departure, mode_params_override: RELAXED_TRANSIT_MODE_PARAMS)
        end
      end

      attempt.result
    end

    def transit_leg(origin, destination, mode)
      # サービス時間内でも、路線ごとの始発・終電時刻外なら「今」を出発時刻にした
      # 問い合わせは ZERO_RESULTS になりうる。その場合のみ翌日の妥当な時間帯で
      # 再試行する（1路線ごとの時刻表までは把握できないための best-effort）。
      departure = departure_time
      attempt = fetch_leg(origin, destination, mode, departure)

      if attempt.retryable
        retry_departure = retry_departure_time
        if retry_departure != departure
          departure = retry_departure
          attempt = fetch_leg(origin, destination, mode, departure)
        end
      end
      return attempt.result unless attempt.retryable

      fetch_leg(origin, destination, mode, departure,
                mode_params_override: RELAXED_TRANSIT_MODE_PARAMS).result
    end

    def fetch_leg(origin, destination, mode, departure_time, mode_params_override: nil)
      body = request(build_url(origin, destination, mode, departure_time, mode_params_override))
      return Attempt.new(nil, false) unless body

      status = body['status']
      if status != 'OK'
        Rails.logger.warn(
          "DirectionsService non-OK status: #{status} mode=#{mode.inspect} " \
          "origin=#{origin.latitude},#{origin.longitude} destination=#{destination.latitude},#{destination.longitude} " \
          "#{body['error_message']}".strip
        )
        return Attempt.new(nil, TRANSIT_RETRYABLE_STATUSES.include?(status))
      end

      Attempt.new(extract_leg(body), false)
    end

    def api_key
      ENV['GOOGLE_DIRECTIONS_API_KEY'].presence || ENV['GOOGLE_MAPS_API_KEY'].presence
    end

    def coordinates?(spot)
      spot.respond_to?(:latitude) && spot.latitude.present? &&
        spot.respond_to?(:longitude) && spot.longitude.present?
    end

    def mode_params(transport)
      TRANSPORT_MODES.fetch(transport.to_s, DEFAULT_MODE)
    end

    def transit?(transport)
      mode_params(transport)[:mode] == 'transit'
    end

    # サービス時間内なら「今」、時間外なら直近の TRANSIT_FALLBACK_DEPARTURE_HOUR 時
    # （今日または翌日）の Unix タイムスタンプを返す。
    def departure_time
      now = Time.zone.now
      return now.to_i if (TRANSIT_SERVICE_START_HOUR...TRANSIT_SERVICE_END_HOUR).cover?(now.hour)

      base = now.hour < TRANSIT_SERVICE_START_HOUR ? now : now + 1.day
      base.change(hour: TRANSIT_FALLBACK_DEPARTURE_HOUR, min: 0, sec: 0).to_i
    end

    # 1 回目の問い合わせが失敗した場合の再試行用の出発時刻。翌日の
    # TRANSIT_FALLBACK_DEPARTURE_HOUR 時（ほぼ全路線が運行しているはずの時間帯）を返す。
    def retry_departure_time
      (Time.zone.now + 1.day).change(hour: TRANSIT_FALLBACK_DEPARTURE_HOUR, min: 0, sec: 0).to_i
    end

    def build_url(origin, destination, transport, departure_time, mode_params_override = nil)
      params = {
        origin: "#{origin.latitude},#{origin.longitude}",
        destination: "#{destination.latitude},#{destination.longitude}",
        key: api_key
      }.merge(mode_params_override || mode_params(transport))
      params[:departure_time] = departure_time if departure_time

      uri = URI(ENDPOINT)
      uri.query = URI.encode_www_form(params)
      uri
    end

    def request(uri)
      response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true,
                                                         open_timeout: OPEN_TIMEOUT, read_timeout: READ_TIMEOUT) do |http|
        http.request(Net::HTTP::Get.new(uri))
      end
      return nil unless response.code.to_i == 200

      JSON.parse(response.body)
    rescue ::JSON::ParserError, ::Net::ProtocolError, ::SocketError, ::SystemCallError,
           ::IOError, ::Timeout::Error, ::OpenSSL::SSL::SSLError => e
      # ベストエフォート: 接続リセット/拒否(Errno::*)・タイムアウト・EOF などの
      # 一時的なネットワーク失敗は握りつぶし、呼び出し側で直線距離フォールバックに任せる。
      # （ルート作成・更新はコミット済みのため、ここで例外を伝播させて 500 にしない）
      Rails.logger.warn("DirectionsService request failed: #{e.class} #{e.message}")
      nil
    end

    def extract_leg(body)
      route = body.dig('routes', 0)
      leg = route&.dig('legs', 0)
      return nil unless leg

      distance = leg.dig('distance', 'value')
      duration = leg.dig('duration', 'value')
      return nil unless distance && duration

      # 実際の道なりの経路を地図に描画するためのエンコード済みポリライン（Google Encoded
      # Polyline Algorithm Format）。未取得でも distance/duration は有効に使えるので nil 許容。
      polyline = route.dig('overview_polyline', 'points')

      { distance_meters: distance.to_i, duration_seconds: duration.to_i, polyline: polyline }
    end
  end
end
