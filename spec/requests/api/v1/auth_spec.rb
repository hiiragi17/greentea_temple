require 'rails_helper'

RSpec.describe 'Api::V1::Auth', type: :request do
  describe 'POST /api/v1/auth/:provider' do
    let(:line_user_info) do
      { provider: 'line', uid: 'U1234567890abcdef', name: 'もちもち抹茶' }
    end

    context 'with valid LINE access_token' do
      before do
        allow(OauthUserInfoFetcher).to receive(:fetch)
          .with('line', hash_including(access_token: 'valid_line_token'))
          .and_return(line_user_info)
      end

      it 'creates a new User + Authentication and returns jwt + user' do
        expect {
          post '/api/v1/auth/line', params: { access_token: 'valid_line_token' }
        }.to change(User, :count).by(1).and change(Authentication, :count).by(1)

        expect(response).to have_http_status(:ok)
        body = response.parsed_body
        expect(body['token']).to be_a(String).and be_present
        expect(body['user']).to include('id', 'name', 'role')
        expect(body['user']['name']).to eq('もちもち抹茶')

        auth = Authentication.last
        expect(auth.provider).to eq('line')
        expect(auth.uid).to eq('U1234567890abcdef')
        expect(auth.user.name).to eq('もちもち抹茶')
      end

      it 'returns the existing User when the same (provider, uid) is already linked' do
        existing_user = User.create!(name: '既存ユーザー')
        Authentication.create!(user: existing_user, provider: 'line', uid: 'U1234567890abcdef')

        expect {
          post '/api/v1/auth/line', params: { access_token: 'valid_line_token' }
        }.not_to change(User, :count)

        expect(response).to have_http_status(:ok)
        body = response.parsed_body
        expect(body['user']['id']).to eq(existing_user.id)
        decoded = JwtService.decode(body['token'])
        expect(decoded['user_id']).to eq(existing_user.id)
      end

      it 'embeds user_id and provider in the JWT and sets exp ~7 days ahead' do
        post '/api/v1/auth/line', params: { access_token: 'valid_line_token' }

        decoded = JwtService.decode(response.parsed_body['token'])
        expect(decoded['user_id']).to eq(User.last.id)
        expect(decoded['provider']).to eq('line')
        expect(decoded['exp']).to be_within(60).of(7.days.from_now.to_i)
      end

      it 'recovers from RecordNotUnique race by re-finding the Authentication' do
        existing_user = User.create!(name: '別タブで先にログイン')
        Authentication.create!(user: existing_user, provider: 'line', uid: 'U1234567890abcdef')

        # 一度 find_by を nil に倒し、create! で RecordNotUnique を発生させる
        allow(Authentication).to receive(:find_by).and_call_original
        allow(Authentication).to receive(:find_by)
          .with(provider: 'line', uid: 'U1234567890abcdef')
          .and_return(nil, existing_user.authentications.first)

        expect {
          post '/api/v1/auth/line', params: { access_token: 'valid_line_token' }
        }.not_to change(Authentication, :count)

        expect(response).to have_http_status(:ok)
        expect(response.parsed_body['user']['id']).to eq(existing_user.id)
      end
    end

    context 'with valid Google access_token' do
      before do
        allow(OauthUserInfoFetcher).to receive(:fetch)
          .with('google', hash_including(access_token: 'google_token'))
          .and_return(provider: 'google', uid: '1234567890', name: 'matcha_san')
      end

      it 'creates the User via Google provider' do
        post '/api/v1/auth/google', params: { access_token: 'google_token' }

        expect(response).to have_http_status(:ok)
        body = response.parsed_body
        expect(body['token']).to be_a(String).and be_present
        expect(body['user']).to include('id', 'name', 'role')
        expect(body['user']['name']).to eq('matcha_san')

        expect(Authentication.last).to have_attributes(provider: 'google', uid: '1234567890')
      end
    end

    context 'with the removed Twitter provider' do
      it 'returns 404 (route constraint no longer allows twitter)' do
        post '/api/v1/auth/twitter', params: { access_token: 'tw_token' }
        expect(response).to have_http_status(:not_found)
      end
    end

    context 'when provider verification fails' do
      before do
        allow(OauthUserInfoFetcher).to receive(:fetch)
          .and_raise(OauthUserInfoFetcher::FetchError, 'invalid token')
      end

      it 'returns 401 without creating a User' do
        expect {
          post '/api/v1/auth/line', params: { access_token: 'bogus' }
        }.not_to change(User, :count)

        expect(response).to have_http_status(:unauthorized)
        expect(response.parsed_body).to eq('error' => 'Unauthorized')
      end
    end

    context 'with unsupported provider' do
      it 'returns 404 (route constraint blocks the path)' do
        post '/api/v1/auth/facebook', params: { access_token: 'x' }
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe 'DELETE /api/v1/auth/logout' do
    let(:user) { User.create!(name: '抹茶ファン') }

    def auth_header(token)
      { 'Authorization' => "Bearer #{token}" }
    end

    it 'returns 204 without a token' do
      delete '/api/v1/auth/logout'
      expect(response).to have_http_status(:no_content)
    end

    it 'returns 204 for an invalid token and changes no token_version' do
      expect {
        delete '/api/v1/auth/logout', headers: auth_header('garbage')
      }.not_to(change { user.reload.token_version })

      expect(response).to have_http_status(:no_content)
    end

    it 'revokes the presented token' do
      token = JwtService.encode(user_id: user.id, ver: user.token_version)

      delete '/api/v1/auth/logout', headers: auth_header(token)
      expect(response).to have_http_status(:no_content)
      expect(user.reload.token_version).to eq(1)

      get '/api/v1/current_user', headers: auth_header(token)
      expect(response).to have_http_status(:unauthorized)
    end

    it 'also revokes tokens issued earlier on other devices' do
      other_device_token = JwtService.encode(user_id: user.id, ver: user.token_version)
      this_device_token = JwtService.encode(user_id: user.id, ver: user.token_version)

      delete '/api/v1/auth/logout', headers: auth_header(this_device_token)
      get '/api/v1/current_user', headers: auth_header(other_device_token)

      expect(response).to have_http_status(:unauthorized)
    end

    it 'revokes a legacy token that has no ver claim' do
      legacy_token = JwtService.encode(user_id: user.id)

      delete '/api/v1/auth/logout', headers: auth_header(legacy_token)
      get '/api/v1/current_user', headers: auth_header(legacy_token)

      expect(response).to have_http_status(:unauthorized)
    end

    it 'lets the user log in again after logging out' do
      old_token = JwtService.encode(user_id: user.id, ver: user.token_version)
      delete '/api/v1/auth/logout', headers: auth_header(old_token)

      new_token = JwtService.encode(user_id: user.id, ver: user.reload.token_version)
      get '/api/v1/current_user', headers: auth_header(new_token)

      expect(response).to have_http_status(:ok)
    end
  end
end
