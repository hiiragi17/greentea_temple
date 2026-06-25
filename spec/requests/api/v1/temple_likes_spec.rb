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
      it "returns the current user's likes wrapping the full temple (no meta)" do
        liked = create(:temple)
        area = create(:area)
        create(:temple_area, temple: liked, area: area)
        unliked = create(:temple)
        TempleLike.create!(user: user, temple: liked)
        TempleLike.create!(user: other_user, temple: unliked)

        get '/api/v1/temple_likes', headers: auth

        expect(response).to have_http_status(:ok)
        json = response.parsed_body
        expect(json).not_to have_key('meta')

        likes = json['temple_likes']
        expect(likes.map { |l| l['temple']['id'] }).to eq([liked.id])

        element = likes.first
        expect(element).to include('id', 'created_at', 'temple')
        spot = element['temple']
        expect(spot).to include(
          'id', 'name', 'description', 'address', 'access', 'phone_number',
          'business_hours', 'holiday', 'homepage', 'img',
          'latitude', 'longitude', 'areas', 'likes_count', 'liked_by_current_user'
        )
        expect(spot['liked_by_current_user']).to eq(true)
        expect(spot['likes_count']).to eq(1)
        expect(spot['areas'].map { |a| a['id'] }).to eq([area.id])
        # temple に closed は無い
        expect(spot).not_to include('closed')
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
      it 'creates a like and returns the wrapped temple' do
        expect {
          post '/api/v1/temple_likes', params: { temple_id: temple.id }, headers: auth
        }.to change { TempleLike.where(user: user, temple: temple).count }.from(0).to(1)

        expect(response).to have_http_status(:ok)
        like = response.parsed_body['temple_like']
        expect(like).to include('id', 'created_at', 'temple')
        expect(like['temple']['id']).to eq(temple.id)
        expect(like['temple']['likes_count']).to eq(1)
        expect(like['temple']['liked_by_current_user']).to eq(true)
      end

      it 'is idempotent: re-POST returns 200 without creating a duplicate' do
        TempleLike.create!(user: user, temple: temple)

        expect {
          post '/api/v1/temple_likes', params: { temple_id: temple.id }, headers: auth
        }.not_to change(TempleLike, :count)

        expect(response).to have_http_status(:ok)
        expect(response.parsed_body['temple_like']['temple']['id']).to eq(temple.id)
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
      it 'deletes the like with :id = temple_id and returns 204' do
        TempleLike.create!(user: user, temple: temple)

        expect {
          delete "/api/v1/temple_likes/#{temple.id}", headers: auth
        }.to change(TempleLike, :count).by(-1)

        expect(response).to have_http_status(:no_content)
      end

      it 'returns 404 when no like exists' do
        delete "/api/v1/temple_likes/#{temple.id}", headers: auth
        expect(response).to have_http_status(:not_found)
      end

      it "never deletes another user's like" do
        TempleLike.create!(user: other_user, temple: temple)

        expect {
          delete "/api/v1/temple_likes/#{temple.id}", headers: auth
        }.not_to change(TempleLike, :count)

        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
