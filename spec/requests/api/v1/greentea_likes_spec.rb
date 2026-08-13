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
      it 'returns the current user\'s likes with nested greentea and meta' do
        liked = create(:greentea)
        unliked = create(:greentea)
        like = GreenteaLike.create!(user: user, greentea: liked)
        GreenteaLike.create!(user: other_user, greentea: unliked)

        get '/api/v1/greentea_likes', headers: auth

        expect(response).to have_http_status(:ok)
        json = response.parsed_body
        items = json['greentea_likes']
        expect(items.map { |d| d['id'] }).to eq([like.id])
        expect(items.first['created_at']).to be_present
        expect(items.first['greentea']).to include(
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

  describe 'POST /api/v1/greentea_likes' do
    context 'when unauthenticated' do
      it 'returns 401' do
        post '/api/v1/greentea_likes', params: { greentea_id: greentea.id }
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when authenticated' do
      it 'creates a like and returns greentea_like with nested greentea' do
        expect {
          post '/api/v1/greentea_likes', params: { greentea_id: greentea.id }, headers: auth
        }.to change { GreenteaLike.where(user: user, greentea: greentea).count }.from(0).to(1)

        expect(response).to have_http_status(:ok)
        body = response.parsed_body['greentea_like']
        expect(body['id']).to eq(GreenteaLike.find_by!(user: user, greentea: greentea).id)
        expect(body['created_at']).to be_present
        expect(body['greentea']).to include('id' => greentea.id, 'likes_count' => 1)
      end

      it 'is idempotent: re-POST returns 200 without creating a duplicate' do
        GreenteaLike.create!(user: user, greentea: greentea)

        expect {
          post '/api/v1/greentea_likes', params: { greentea_id: greentea.id }, headers: auth
        }.not_to change(GreenteaLike, :count)

        expect(response).to have_http_status(:ok)
        expect(response.parsed_body['greentea_like']['greentea']).to include('likes_count' => 1)
      end

      it 'is idempotent even when the race raises RecordInvalid (validation)' do
        GreenteaLike.create!(user: user, greentea: greentea)
        allow_any_instance_of(ActiveRecord::Relation)
          .to receive(:find_or_create_by!)
          .and_raise(ActiveRecord::RecordInvalid.new(GreenteaLike.new))

        post '/api/v1/greentea_likes', params: { greentea_id: greentea.id }, headers: auth

        expect(response).to have_http_status(:ok)
        expect(response.parsed_body['greentea_like']['greentea']).to include('likes_count' => 1)
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
      it 'deletes the current user\'s like with :id = greentea_id and returns 204' do
        GreenteaLike.create!(user: user, greentea: greentea)

        expect {
          delete "/api/v1/greentea_likes/#{greentea.id}", headers: auth
        }.to change(GreenteaLike, :count).by(-1)

        expect(response).to have_http_status(:no_content)
        expect(response.body).to be_blank
      end

      it 'returns 404 when no like exists' do
        delete "/api/v1/greentea_likes/#{greentea.id}", headers: auth
        expect(response).to have_http_status(:not_found)
        expect(response.headers['Cache-Control']).to eq('no-store')
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
