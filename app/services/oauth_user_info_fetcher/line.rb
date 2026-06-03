require 'net/http'
require 'openssl'
require 'json'

module OauthUserInfoFetcher
  class Line
    PROFILE_URL = URI('https://api.line.me/v2/profile').freeze
    OPEN_TIMEOUT = 5
    READ_TIMEOUT = 5

    def initialize(access_token:)
      @access_token = access_token
    end

    def call
      raise FetchError, 'access_token is required' if @access_token.blank?

      response = fetch_profile
      raise FetchError, "LINE API error: #{response.code}" unless response.code.to_i == 200

      payload = JSON.parse(response.body)
      {
        provider: 'line',
        uid: payload['userId'].to_s,
        name: payload['displayName']
      }
    rescue ::JSON::ParserError => e
      raise FetchError, "Invalid LINE response: #{e.message}"
    rescue ::Net::OpenTimeout, ::Net::ReadTimeout, ::SocketError, ::OpenSSL::SSL::SSLError => e
      raise FetchError, "LINE request failed: #{e.message}"
    end

    private

    def fetch_profile
      request = Net::HTTP::Get.new(PROFILE_URL)
      request['Authorization'] = "Bearer #{@access_token}"
      Net::HTTP.start(PROFILE_URL.hostname, PROFILE_URL.port,
                      use_ssl: true, open_timeout: OPEN_TIMEOUT, read_timeout: READ_TIMEOUT) do |http|
        http.request(request)
      end
    end
  end
end
