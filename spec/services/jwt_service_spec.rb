require 'rails_helper'

RSpec.describe JwtService do
  describe '.encode / .decode' do
    it 'round-trips a payload and exposes the claims' do
      token = described_class.encode(user_id: 42)
      payload = described_class.decode(token)

      expect(payload['user_id']).to eq(42)
      expect(payload['exp']).to be_a(Integer)
    end

    it 'accepts a payload passed as a positional hash' do
      token = described_class.encode({ 'role' => 'admin' })
      payload = described_class.decode(token)

      expect(payload['role']).to eq('admin')
    end

    it 'sets the expiry to roughly 14 days from now by default' do
      freeze_time = Time.zone.local(2026, 6, 13, 12, 0, 0)
      Timecop.freeze(freeze_time) do
        payload = described_class.decode(described_class.encode(user_id: 1))
        expect(payload['exp']).to eq(14.days.from_now.to_i)
      end
    end

    it 'honours an explicit expires_at' do
      expires_at = 1.hour.from_now
      payload = described_class.decode(described_class.encode({ user_id: 1 }, expires_at: expires_at))

      expect(payload['exp']).to eq(expires_at.to_i)
    end
  end

  describe '.decode error handling' do
    it 'raises InvalidTokenError for a malformed token' do
      expect { described_class.decode('not-a-jwt') }
        .to raise_error(JwtService::InvalidTokenError)
    end

    it 'raises InvalidTokenError when the signature does not match' do
      forged = ::JWT.encode({ user_id: 1, exp: 1.day.from_now.to_i }, 'wrong-secret', 'HS256')

      expect { described_class.decode(forged) }
        .to raise_error(JwtService::InvalidTokenError)
    end

    it 'raises ExpiredTokenError for an expired token' do
      token = nil
      Timecop.freeze(2.days.ago) do
        token = described_class.encode({ user_id: 1 }, expires_at: 1.day.from_now)
      end

      expect { described_class.decode(token) }
        .to raise_error(JwtService::ExpiredTokenError)
    end
  end

  describe 'secret resolution' do
    around do |example|
      original = ENV['JWT_SECRET_KEY']
      example.run
      ENV['JWT_SECRET_KEY'] = original
    end

    it 'prefers ENV["JWT_SECRET_KEY"] when credentials are absent' do
      allow(Rails.application.credentials).to receive(:[]).with(:jwt_secret).and_return(nil)
      ENV['JWT_SECRET_KEY'] = 'env-secret'

      token = described_class.encode(user_id: 7)
      decoded = ::JWT.decode(token, 'env-secret', true, algorithm: 'HS256').first

      expect(decoded['user_id']).to eq(7)
    end

    it 'prefers credentials over ENV when both are set' do
      allow(Rails.application.credentials).to receive(:[]).with(:jwt_secret).and_return('cred-secret')
      ENV['JWT_SECRET_KEY'] = 'env-secret'

      token = described_class.encode(user_id: 7)
      decoded = ::JWT.decode(token, 'cred-secret', true, algorithm: 'HS256').first

      expect(decoded['user_id']).to eq(7)
    end

    it 'falls back to a deterministic secret in the test environment' do
      allow(Rails.application.credentials).to receive(:[]).with(:jwt_secret).and_return(nil)
      ENV['JWT_SECRET_KEY'] = nil

      token = described_class.encode(user_id: 7)
      decoded = ::JWT.decode(token, 'test_jwt_secret_do_not_use_in_production', true, algorithm: 'HS256').first

      expect(decoded['user_id']).to eq(7)
    end
  end
end
