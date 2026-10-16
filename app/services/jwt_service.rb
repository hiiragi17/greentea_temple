class JwtService
  ALGORITHM = 'HS256'.freeze
  # フロント (NextAuth) の session.maxAge と揃えること。ずれると Cookie 上はログイン済みなのに
  # API だけ 401 になる期間ができる。
  EXPIRES_IN = 7.days
  ISSUER = 'greentea_temple'.freeze
  AUDIENCE = 'matcha-to-jinja'.freeze

  class Error < StandardError; end
  class InvalidTokenError < Error; end
  class ExpiredTokenError < Error; end
  class MissingSecretError < Error; end

  class << self
    # payload はハッシュ位置引数でも、キーワード（encode(user_id: 1, ...)）でも受けられるようにする。
    # Ruby 3 ではキーワード分離により、expires_at を持つ本メソッドへ素のキーワードを渡すと
    # payload が満たされず ArgumentError になるため、**extra で吸収する。
    def encode(payload = nil, expires_at: EXPIRES_IN.from_now, **extra)
      claims = (payload || {}).merge(extra).merge(
        exp: expires_at.to_i, iat: Time.current.to_i, iss: ISSUER, aud: AUDIENCE
      )
      ::JWT.encode(claims, secret_key, ALGORITHM)
    end

    def decode(token)
      payload, _header = ::JWT.decode(token, secret_key, true, algorithm: ALGORITHM, required_claims: ['exp'])
      verify_issuer_and_audience!(payload)
      payload
    rescue ::JWT::ExpiredSignature => e
      raise ExpiredTokenError, e.message
    rescue ::JWT::DecodeError => e
      raise InvalidTokenError, e.message
    end

    private

    # iss / aud は導入前（2026-10 以前）に発行されたトークンに無いため、存在する場合だけ検証する。
    # 導入前のトークンは最長14日で期限切れになるので、それ以降は必須化してよい。
    def verify_issuer_and_audience!(payload)
      raise InvalidTokenError, 'Invalid issuer' if payload.key?('iss') && payload['iss'] != ISSUER
      raise InvalidTokenError, 'Invalid audience' if payload.key?('aud') && payload['aud'] != AUDIENCE
    end

    def secret_key
      credentials_key = Rails.application.credentials[:jwt_secret].presence
      env_key = ENV['JWT_SECRET_KEY'].presence
      return credentials_key || env_key if credentials_key || env_key

      unless Rails.env.test?
        raise MissingSecretError,
              'JWT secret is not configured. Set credentials :jwt_secret or ENV["JWT_SECRET_KEY"].'
      end

      'test_jwt_secret_do_not_use_in_production'
    end
  end
end
