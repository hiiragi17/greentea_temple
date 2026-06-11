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

  class << self
    # origin / destination は latitude / longitude を持つオブジェクト（Greentea / Temple）。
    # mode は route_spots.transport の文字列（"walk" / "train" など、nil 可）。
    # 返り値: { distance_meters: Integer, duration_seconds: Integer } または nil。
    def leg(origin:, destination:, mode: nil)
      key = api_key
      return nil if key.blank?
      return nil unless coordinates?(origin) && coordinates?(destination)

      body = request(build_url(origin, destination, mode, key))
      return nil unless body

      parse(body)
    end

    private

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

    def build_url(origin, destination, transport, key)
      params = {
        origin: "#{origin.latitude},#{origin.longitude}",
        destination: "#{destination.latitude},#{destination.longitude}",
        key: key
      }.merge(mode_params(transport))

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

    def parse(body)
      return nil unless body['status'] == 'OK'

      leg = body.dig('routes', 0, 'legs', 0)
      return nil unless leg

      distance = leg.dig('distance', 'value')
      duration = leg.dig('duration', 'value')
      return nil unless distance && duration

      { distance_meters: distance.to_i, duration_seconds: duration.to_i }
    end
  end
end
