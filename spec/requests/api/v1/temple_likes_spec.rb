require 'rails_helper'

RSpec.describe 'Api::V1::TempleLikes', type: :request do
  let(:user) { User.create!(name: 'いいねユーザー') }
  let(:other_user) { User.create!(name: '他人') }
  let(:temple) { create(:temple) }
  let(:token) { JwtService.encode({ user_id: user.id }) }
  let(:auth) { { 'Authorization' => "Bearer #{token}" } }

  describe 'GET /api/v1/temple_likes' do
    context 'when unauthenticated' do
      it 'returns 401' do
        get '/api/v1/temple_likes'
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when authenticated' do
      it 'returns the current user\'s liked temples' do
        liked = create(:temple)
        unliked = create(:temple)
        TempleLike.create!(user: user, temple: liked)
        TempleLike.create!(user: other_user, temple: unliked)

        get '/api/v1/temple_likes', headers: auth

        expect(response).to have_http_status(:ok)
        json = response.parsed_body
        ids = json['data'].map { |d| d['id'] }
        expect(ids).to eq([liked.id])
        expect(json['data'].first['liked_by_current_user']).to eq(true)
        expect(json['meta']).to include(
          'current_page' => 1,
          'total_pages' => 1,
          'total_count' => 1,
          'per_page' => 15
        )
      end
    end
  end

  describe 'POST /api/v1/temple_likes' do
    context 'when unauthenticated' do
      it 'returns 401' do
        post '/api/v1/temple_likes', params: { temple_id: temple.id }
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when authenticated' do
      it 'creates a like and returns 200' do
        expect {
          post '/api/v1/temple_likes', params: { temple_id: temple.id }, headers: auth
        }.to change { TempleLike.where(user: user, temple: temple).count }.from(0).to(1)

        expect(response).to have_http_status(:ok)
        expect(response.parsed_body['data']).to include(
          'temple_id' => temple.id,
          'liked' => true,
          'like_count' => 1
        )
      end

      it 'is idempotent on duplicate POST' do
        TempleLike.create!(user: user, temple: temple)

        expect {
          post '/api/v1/temple_likes', params: { temple_id: temple.id }, headers: auth
        }.not_to change(TempleLike, :count)

        expect(response).to have_http_status(:ok)
      end

      it 'returns 404 when temple does not exist' do
        post '/api/v1/temple_likes', params: { temple_id: 999_999 }, headers: auth
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe 'DELETE /api/v1/temple_likes/:id' do
    context 'when unauthenticated' do
      it 'returns 401' do
        delete "/api/v1/temple_likes/#{temple.id}"
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when authenticated' do
      it 'deletes the current user\'s like with :id = temple_id' do
        TempleLike.create!(user: user, temple: temple)

        expect {
          delete "/api/v1/temple_likes/#{temple.id}", headers: auth
        }.to change(TempleLike, :count).by(-1)

        expect(response).to have_http_status(:ok)
      end

      it 'returns 404 when no like exists' do
        delete "/api/v1/temple_likes/#{temple.id}", headers: auth
        expect(response).to have_http_status(:not_found)
      end

      it 'never deletes another user\'s like' do
        TempleLike.create!(user: other_user, temple: temple)

        expect {
          delete "/api/v1/temple_likes/#{temple.id}", headers: auth
        }.not_to change(TempleLike, :count)

        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
