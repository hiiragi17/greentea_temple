class JwtService
  ALGORITHM = 'HS256'.freeze
  EXPIRES_IN = 14.days

  class Error < StandardError; end
  class InvalidTokenError < Error; end
  class ExpiredTokenError < Error; end
  class MissingSecretError < Error; end

  class << self
    def encode(payload, expires_at: EXPIRES_IN.from_now)
      claims = payload.merge(exp: expires_at.to_i)
      ::JWT.encode(claims, secret_key, ALGORITHM)
    end

    def decode(token)
      payload, _header = ::JWT.decode(token, secret_key, true, algorithm: ALGORITHM)
      payload
    rescue ::JWT::ExpiredSignature => e
      raise ExpiredTokenError, e.message
    rescue ::JWT::DecodeError => e
      raise InvalidTokenError, e.message
    end

    private

    def secret_key
      credentials_key = Rails.application.credentials.dig(:jwt_secret).presence
      env_key = ENV['JWT_SECRET_KEY'].presence
      return credentials_key || env_key if credentials_key || env_key

      raise MissingSecretError,
            'JWT secret is not configured. Set credentials :jwt_secret or ENV["JWT_SECRET_KEY"].' unless Rails.env.test?

      'test_jwt_secret_do_not_use_in_production'
    end
  end
end
