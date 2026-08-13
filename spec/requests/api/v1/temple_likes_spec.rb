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
      it 'returns the current user\'s likes with nested temple and meta' do
        liked = create(:temple)
        unliked = create(:temple)
        like = TempleLike.create!(user: user, temple: liked)
        TempleLike.create!(user: other_user, temple: unliked)

        get '/api/v1/temple_likes', headers: auth

        expect(response).to have_http_status(:ok)
        json = response.parsed_body
        items = json['temple_likes']
        expect(items.map { |d| d['id'] }).to eq([like.id])
        expect(items.first['created_at']).to be_present
        expect(items.first['temple']).to include(
          'id' => liked.id,
          'name' => liked.name,
          'likes_count' => 1
        )
        expect(json['meta']).to include(
          'current_page' => 1,
          'total_pages' => 1,
          'total_count' => 1
        )
        expect(json['meta']).not_to include('per_page')
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
      it 'creates a like and returns temple_like with nested temple' do
        expect {
          post '/api/v1/temple_likes', params: { temple_id: temple.id }, headers: auth
        }.to change { TempleLike.where(user: user, temple: temple).count }.from(0).to(1)

        expect(response).to have_http_status(:ok)
        body = response.parsed_body['temple_like']
        expect(body['created_at']).to be_present
        expect(body['temple']).to include('id' => temple.id, 'likes_count' => 1)
      end

      it 'is idempotent on duplicate POST' do
        TempleLike.create!(user: user, temple: temple)

        expect {
          post '/api/v1/temple_likes', params: { temple_id: temple.id }, headers: auth
        }.not_to change(TempleLike, :count)

        expect(response).to have_http_status(:ok)
        expect(response.parsed_body['temple_like']['temple']).to include('likes_count' => 1)
      end

      it 'is idempotent even when the race raises RecordInvalid (validation)' do
        TempleLike.create!(user: user, temple: temple)
        allow_any_instance_of(ActiveRecord::Relation)
          .to receive(:find_or_create_by!)
          .and_raise(ActiveRecord::RecordInvalid.new(TempleLike.new))

        post '/api/v1/temple_likes', params: { temple_id: temple.id }, headers: auth

        expect(response).to have_http_status(:ok)
        expect(response.parsed_body['temple_like']['temple']).to include('likes_count' => 1)
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
      it 'deletes the current user\'s like with :id = temple_id and returns 204' do
        TempleLike.create!(user: user, temple: temple)

        expect {
          delete "/api/v1/temple_likes/#{temple.id}", headers: auth
        }.to change(TempleLike, :count).by(-1)

        expect(response).to have_http_status(:no_content)
        expect(response.body).to be_blank
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
