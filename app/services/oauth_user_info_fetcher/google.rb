require 'net/http'
require 'openssl'
require 'json'

module OauthUserInfoFetcher
  class Google
    USERINFO_URL = URI('https://www.googleapis.com/oauth2/v3/userinfo').freeze
    OPEN_TIMEOUT = 5
    READ_TIMEOUT = 5

    def initialize(access_token:)
      @access_token = access_token
    end

    def call
      raise FetchError, 'access_token is required' if @access_token.blank?

      response = fetch_userinfo
      unless response.code.to_i == 200
        raise FetchError, "Google API error: #{response.code} - #{response.body}"
      end

      payload = JSON.parse(response.body)
      uid = payload['sub'].to_s
      raise FetchError, 'Google response missing sub (uid)' if uid.empty?

      {
        provider: 'google',
        uid: uid,
        name: payload['name'].presence || payload['email']
      }
    rescue ::JSON::ParserError => e
      raise FetchError, "Invalid Google response: #{e.message}"
    rescue ::Net::OpenTimeout, ::Net::ReadTimeout, ::SocketError, ::OpenSSL::SSL::SSLError => e
      raise FetchError, "Google request failed: #{e.message}"
    end

    private

    def fetch_userinfo
      request = Net::HTTP::Get.new(USERINFO_URL)
      request['Authorization'] = "Bearer #{@access_token}"
      Net::HTTP.start(USERINFO_URL.hostname, USERINFO_URL.port,
                      use_ssl: true, open_timeout: OPEN_TIMEOUT, read_timeout: READ_TIMEOUT) do |http|
        http.request(request)
      end
    end
  end
end
