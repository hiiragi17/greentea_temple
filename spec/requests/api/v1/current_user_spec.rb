require 'rails_helper'

RSpec.describe 'Api::V1::CurrentUser', type: :request do
  describe 'GET /api/v1/current_user' do
    let(:user) { User.create!(name: '抹茶ファン1号') }

    def auth_header(token)
      { 'Authorization' => "Bearer #{token}" }
    end

    context 'with a valid JWT' do
      it 'returns 200 with the user payload' do
        token = JwtService.encode(user_id: user.id)

        get '/api/v1/current_user', headers: auth_header(token)

        expect(response).to have_http_status(:ok)
        body = response.parsed_body
        expect(body['user']).to include(
          'id' => user.id,
          'name' => '抹茶ファン1号'
        )
        expect(body['user']).to have_key('role')
      end
    end

    context 'without a token' do
      it 'returns 401' do
        get '/api/v1/current_user'

        expect(response).to have_http_status(:unauthorized)
        expect(response.parsed_body).to eq('error' => 'Unauthorized')
      end
    end

    context 'with a malformed Authorization header' do
      it 'returns 401' do
        get '/api/v1/current_user', headers: { 'Authorization' => 'token-without-bearer' }
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'with an invalid signature' do
      it 'returns 401' do
        bogus = JWT.encode({ user_id: user.id, exp: 1.hour.from_now.to_i }, 'wrong_secret', 'HS256')
        get '/api/v1/current_user', headers: auth_header(bogus)
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'with an expired JWT' do
      it 'returns 401' do
        token = JwtService.encode({ user_id: user.id }, expires_at: 1.minute.ago)
        get '/api/v1/current_user', headers: auth_header(token)

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when the user no longer exists' do
      it 'returns 401' do
        token = JwtService.encode(user_id: user.id)
        user.destroy!

        get '/api/v1/current_user', headers: auth_header(token)
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
end
