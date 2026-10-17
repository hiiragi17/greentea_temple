require 'rails_helper'

RSpec.describe 'CORS', type: :request do
  let(:allowed_origin) { ENV.fetch('FRONTEND_URL', 'http://localhost:3000') }

  describe 'OPTIONS /api/v1/greenteas (preflight)' do
    def preflight(origin)
      options '/api/v1/greenteas', headers: {
        'Origin' => origin,
        'Access-Control-Request-Method' => 'GET',
        'Access-Control-Request-Headers' => 'authorization'
      }
    end

    it 'allows the frontend origin' do
      preflight(allowed_origin)

      expect(response.headers['Access-Control-Allow-Origin']).to eq(allowed_origin)
      expect(response.headers['Access-Control-Allow-Headers'].to_s.downcase).to include('authorization')
    end

    it 'does not allow credentials (auth is Bearer header only)' do
      preflight(allowed_origin)

      expect(response.headers).not_to have_key('Access-Control-Allow-Credentials')
    end

    it 'does not allow other origins' do
      preflight('https://evil.example.com')

      expect(response.headers).not_to have_key('Access-Control-Allow-Origin')
    end
  end

  describe 'GET /api/v1/health' do
    it 'does not send credentials or expose any response header on a simple request' do
      get '/api/v1/health', headers: { 'Origin' => allowed_origin }

      expect(response.headers['Access-Control-Allow-Origin']).to eq(allowed_origin)
      expect(response.headers).not_to have_key('Access-Control-Allow-Credentials')
      # Rack::Cors は expose 未指定でも空値のヘッダーを付ける。Authorization を公開していないことを検証する。
      expect(response.headers['Access-Control-Expose-Headers'].to_s).to be_empty
    end
  end
end
