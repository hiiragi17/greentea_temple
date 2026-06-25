require 'rails_helper'

RSpec.describe 'Api::V1::GreenteaLikes', type: :request do
  let(:user) { User.create!(name: 'いいねユーザー') }
  let(:other_user) { User.create!(name: '他人') }
  let(:greentea) { create(:greentea) }
  let(:token) { JwtService.encode({ user_id: user.id }) }
  let(:auth) { { 'Authorization' => "Bearer #{token}" } }

  describe 'GET /api/v1/greentea_likes' do
    context 'when unauthenticated' do
      it 'returns 401' do
        get '/api/v1/greentea_likes'
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when authenticated' do
      it 'returns the current user\'s liked greenteas with meta' do
        liked = create(:greentea)
        unliked = create(:greentea)
        GreenteaLike.create!(user: user, greentea: liked)
        GreenteaLike.create!(user: other_user, greentea: unliked)

        get '/api/v1/greentea_likes', headers: auth

        expect(response).to have_http_status(:ok)
        json = response.parsed_body
        ids = json['data'].map { |d| d['id'] }
        expect(ids).to eq([liked.id])
        expect(json['meta']).to include(
          'current_page' => 1,
          'total_pages' => 1,
          'total_count' => 1
        )
        expect(json['meta']).not_to include('per_page')
      end
    end
  end

  describe 'POST /api/v1/greentea_likes' do
    context 'when unauthenticated' do
      it 'returns 401' do
        post '/api/v1/greentea_likes', params: { greentea_id: greentea.id }
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when authenticated' do
      it 'creates a like and returns 200 with like_count' do
        expect {
          post '/api/v1/greentea_likes', params: { greentea_id: greentea.id }, headers: auth
        }.to change { GreenteaLike.where(user: user, greentea: greentea).count }.from(0).to(1)

        expect(response).to have_http_status(:ok)
        body = response.parsed_body['data']
        expect(body).to include(
          'greentea_id' => greentea.id,
          'liked' => true,
          'like_count' => 1
        )
      end

      it 'is idempotent: re-POST returns 200 without creating a duplicate' do
        GreenteaLike.create!(user: user, greentea: greentea)

        expect {
          post '/api/v1/greentea_likes', params: { greentea_id: greentea.id }, headers: auth
        }.not_to change(GreenteaLike, :count)

        expect(response).to have_http_status(:ok)
        expect(response.parsed_body['data']).to include('liked' => true, 'like_count' => 1)
      end

      it 'is idempotent even when the race raises RecordInvalid (validation)' do
        GreenteaLike.create!(user: user, greentea: greentea)
        allow_any_instance_of(ActiveRecord::Relation)
          .to receive(:find_or_create_by!)
          .and_raise(ActiveRecord::RecordInvalid.new(GreenteaLike.new))

        post '/api/v1/greentea_likes', params: { greentea_id: greentea.id }, headers: auth

        expect(response).to have_http_status(:ok)
        expect(response.parsed_body['data']).to include('liked' => true, 'like_count' => 1)
      end

      it 'returns 404 when greentea does not exist' do
        post '/api/v1/greentea_likes', params: { greentea_id: 999_999 }, headers: auth
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe 'DELETE /api/v1/greentea_likes/:id' do
    context 'when unauthenticated' do
      it 'returns 401' do
        delete "/api/v1/greentea_likes/#{greentea.id}"
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when authenticated' do
      it 'deletes the current user\'s like with :id = greentea_id' do
        GreenteaLike.create!(user: user, greentea: greentea)

        expect {
          delete "/api/v1/greentea_likes/#{greentea.id}", headers: auth
        }.to change(GreenteaLike, :count).by(-1)

        expect(response).to have_http_status(:ok)
        body = response.parsed_body['data']
        expect(body).to include(
          'greentea_id' => greentea.id,
          'liked' => false,
          'like_count' => 0
        )
      end

      it 'returns 404 when no like exists' do
        delete "/api/v1/greentea_likes/#{greentea.id}", headers: auth
        expect(response).to have_http_status(:not_found)
      end

      it 'never deletes another user\'s like' do
        GreenteaLike.create!(user: other_user, greentea: greentea)

        expect {
          delete "/api/v1/greentea_likes/#{greentea.id}", headers: auth
        }.not_to change(GreenteaLike, :count)

        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
