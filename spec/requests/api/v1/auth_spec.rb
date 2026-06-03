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
        expect(body['jwt']).to be_a(String).and be_present
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
        decoded = JwtService.decode(body['jwt'])
        expect(decoded['user_id']).to eq(existing_user.id)
      end

      it 'embeds user_id and provider in the JWT and sets exp ~14 days ahead' do
        post '/api/v1/auth/line', params: { access_token: 'valid_line_token' }

        decoded = JwtService.decode(response.parsed_body['jwt'])
        expect(decoded['user_id']).to eq(User.last.id)
        expect(decoded['provider']).to eq('line')
        expect(decoded['exp']).to be_within(60).of(14.days.from_now.to_i)
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

    context 'with valid Twitter access_token + secret' do
      before do
        allow(OauthUserInfoFetcher).to receive(:fetch)
          .with('twitter', hash_including(access_token: 'tw_token', access_token_secret: 'tw_secret'))
          .and_return(provider: 'twitter', uid: '1234567890', name: 'matcha_san')
      end

      it 'creates the User via Twitter provider' do
        post '/api/v1/auth/twitter',
             params: { access_token: 'tw_token', access_token_secret: 'tw_secret' }

        expect(response).to have_http_status(:ok)
        expect(Authentication.last).to have_attributes(provider: 'twitter', uid: '1234567890')
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
    it 'returns 204 (stateless logout)' do
      delete '/api/v1/auth/logout'
      expect(response).to have_http_status(:no_content)
    end
  end
end
