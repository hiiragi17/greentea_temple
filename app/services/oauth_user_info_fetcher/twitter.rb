require 'oauth'
require 'openssl'
require 'json'

module OauthUserInfoFetcher
  class Twitter
    SITE = 'https://api.twitter.com'.freeze
    VERIFY_PATH = '/1.1/account/verify_credentials.json?include_email=true'.freeze
    TIMEOUT = 5

    def initialize(access_token:, access_token_secret:)
      @access_token = access_token
      @access_token_secret = access_token_secret
    end

    def call
      validate_tokens!

      response = fetch_user_info
      raise FetchError, "Twitter API error: #{response.code}" unless response.code.to_i == 200

      build_user_info(JSON.parse(response.body))
    rescue ::OAuth::Unauthorized => e
      raise FetchError, "Twitter unauthorized: #{e.message}"
    rescue ::JSON::ParserError => e
      raise FetchError, "Invalid Twitter response: #{e.message}"
    rescue ::Net::OpenTimeout, ::Net::ReadTimeout, ::SocketError, ::OpenSSL::SSL::SSLError => e
      raise FetchError, "Twitter request failed: #{e.message}"
    rescue ::OAuth::Error => e
      raise FetchError, "Twitter OAuth error: #{e.message}"
    end

    private

    def validate_tokens!
      raise FetchError, 'access_token is required' if @access_token.blank?
      raise FetchError, 'access_token_secret is required' if @access_token_secret.blank?
    end

    def build_user_info(payload)
      {
        provider: 'twitter',
        uid: payload['id_str'].to_s,
        name: payload['name'].presence || payload['screen_name']
      }
    end

    def fetch_user_info
      consumer = ::OAuth::Consumer.new(
        Rails.application.credentials.dig(:twitter, :key),
        Rails.application.credentials.dig(:twitter, :secret_key),
        site: SITE,
        timeout: TIMEOUT
      )
      token = ::OAuth::AccessToken.new(consumer, @access_token, @access_token_secret)
      token.get(VERIFY_PATH)
    end
  end
end
