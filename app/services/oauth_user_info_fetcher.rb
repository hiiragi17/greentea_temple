module OauthUserInfoFetcher
  class FetchError < StandardError; end
  class UnsupportedProviderError < StandardError; end

  SUPPORTED_PROVIDERS = %w[line google].freeze

  def self.fetch(provider, params)
    case provider.to_s
    when 'line'
      Line.new(access_token: params[:access_token]).call
    when 'google'
      Google.new(access_token: params[:access_token]).call
    else
      raise UnsupportedProviderError, "Unsupported provider: #{provider}"
    end
  end
end
