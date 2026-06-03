require 'oauth'
require 'json'

module OauthUserInfoFetcher
  class Twitter
    SITE = 'https://api.twitter.com'.freeze
    VERIFY_PATH = '/1.1/account/verify_credentials.json?include_email=true'.freeze

    def initialize(access_token:, access_token_secret:)
      @access_token = access_token
      @access_token_secret = access_token_secret
    end

    def call
      raise FetchError, 'access_token is required' if @access_token.blank?
      raise FetchError, 'access_token_secret is required' if @access_token_secret.blank?

      response = fetch_user_info
      raise FetchError, "Twitter API error: #{response.code}" unless response.code.to_i == 200

      payload = JSON.parse(response.body)
      {
        provider: 'twitter',
        uid: payload['id_str'].to_s,
        name: payload['name'].presence || payload['screen_name']
      }
    rescue ::OAuth::Unauthorized => e
      raise FetchError, "Twitter unauthorized: #{e.message}"
    rescue ::JSON::ParserError => e
      raise FetchError, "Invalid Twitter response: #{e.message}"
    end

    private

    def fetch_user_info
      consumer = ::OAuth::Consumer.new(
        Rails.application.credentials.dig(:twitter, :key),
        Rails.application.credentials.dig(:twitter, :secret_key),
        site: SITE
      )
      token = ::OAuth::AccessToken.new(consumer, @access_token, @access_token_secret)
      token.get(VERIFY_PATH)
    end
  end
end
