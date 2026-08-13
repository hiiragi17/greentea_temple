require 'rails_helper'

RSpec.describe 'Api::V1::Warmup', type: :request do
  around do |example|
    original = ENV['WARMUP_TOKEN']
    example.run
    ENV['WARMUP_TOKEN'] = original
  end

  describe 'GET /api/v1/warmup' do
    context 'when WARMUP_TOKEN is not configured' do
      it 'returns 401 even without a header (fail closed)' do
        ENV['WARMUP_TOKEN'] = nil

        get '/api/v1/warmup'

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when WARMUP_TOKEN is configured' do
      before { ENV['WARMUP_TOKEN'] = 'test-warmup-token' }

      it 'returns 401 when the header is missing' do
        get '/api/v1/warmup'

        expect(response).to have_http_status(:unauthorized)
      end

      it 'returns 401 when the header does not match' do
        get '/api/v1/warmup', headers: { 'X-Warmup-Token' => 'wrong-token' }

        expect(response).to have_http_status(:unauthorized)
      end

      it 'returns 200 and touches the database when the header matches' do
        get '/api/v1/warmup', headers: { 'X-Warmup-Token' => 'test-warmup-token' }

        expect(response).to have_http_status(:ok)
        expect(response.parsed_body).to eq('status' => 'ok')
        expect(response.headers['Cache-Control']).to eq('no-store')
      end
    end
  end
end
