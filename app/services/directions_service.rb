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

  class << self
    # origin / destination は latitude / longitude を持つオブジェクト（Greentea / Temple）。
    # mode は route_spots.transport の文字列（"walk" / "train" など、nil 可）。
    # 返り値: { distance_meters: Integer, duration_seconds: Integer, polyline: String or nil } または nil。
    def leg(origin:, destination:, mode: nil)
      key = api_key
      return nil if key.blank?
      return nil unless coordinates?(origin) && coordinates?(destination)
      return fetch_leg(origin, destination, mode, key, nil) unless transit?(mode)

      # サービス時間内でも、路線ごとの始発・終電時刻外なら「今」を出発時刻にした
      # 問い合わせは ZERO_RESULTS になりうる。その場合は翌日の妥当な時間帯で
      # 再試行する（1路線ごとの時刻表までは把握できないための best-effort）。
      first_departure = departure_time
      result = fetch_leg(origin, destination, mode, key, first_departure)
      return result if result

      retry_departure = retry_departure_time
      return nil if retry_departure == first_departure

      fetch_leg(origin, destination, mode, key, retry_departure)
    end

    private

    def fetch_leg(origin, destination, mode, key, departure_time)
      body = request(build_url(origin, destination, mode, key, departure_time))
      return nil unless body

      parse(body, mode)
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

    def build_url(origin, destination, transport, key, departure_time)
      params = {
        origin: "#{origin.latitude},#{origin.longitude}",
        destination: "#{destination.latitude},#{destination.longitude}",
        key: key
      }.merge(mode_params(transport))
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

    def parse(body, mode = nil)
      if body['status'] != 'OK'
        Rails.logger.warn(
          "DirectionsService non-OK status: #{body['status']} mode=#{mode.inspect} #{body['error_message']}".strip
        )
        return nil
      end

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
