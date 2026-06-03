module OauthUserInfoFetcher
  class FetchError < StandardError; end
  class UnsupportedProviderError < StandardError; end

  SUPPORTED_PROVIDERS = %w[twitter line].freeze

  def self.fetch(provider, params)
    case provider.to_s
    when 'twitter'
      Twitter.new(
        access_token: params[:access_token],
        access_token_secret: params[:access_token_secret]
      ).call
    when 'line'
      Line.new(access_token: params[:access_token]).call
    else
      raise UnsupportedProviderError, "Unsupported provider: #{provider}"
    end
  end
end
