require 'rails_helper'

RSpec.describe 'Api::V1::Greenteacomments', type: :request do
  let(:user) { User.create!(name: '口コミ投稿者') }
  let(:other_user) { User.create!(name: '他人') }
  let(:greentea) { create(:greentea) }
  let(:token) { JwtService.encode({ user_id: user.id }) }
  let(:auth) { { 'Authorization' => "Bearer #{token}" } }

  describe 'GET /api/v1/greenteacomments' do
    context 'when unauthenticated' do
      it 'returns 401' do
        get '/api/v1/greenteacomments', params: { greentea_id: greentea.id }
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when authenticated' do
      it 'returns comments for the given greentea, newest first' do
        own = Greenteacomment.create!(user: user, greentea: greentea, body: '自分の口コミ', created_at: 1.day.ago)
        other = Greenteacomment.create!(user: other_user, greentea: greentea, body: '他人の口コミ', created_at: 1.hour.ago)
        Greenteacomment.create!(user: user, greentea: create(:greentea), body: '別店')

        get '/api/v1/greenteacomments', params: { greentea_id: greentea.id }, headers: auth

        expect(response).to have_http_status(:ok)
        json = response.parsed_body
        expect(json['meta']).to include('current_page', 'total_pages', 'total_count')
        expect(json['meta']).not_to include('per_page')
        ids = json['data'].map { |d| d['id'] }
        expect(ids).to eq([other.id, own.id])

        own_payload = json['data'].find { |d| d['id'] == own.id }
        expect(own_payload['owned_by_current_user']).to eq(true)
        expect(own_payload['user']).to include('id' => user.id, 'name' => '口コミ投稿者')

        other_payload = json['data'].find { |d| d['id'] == other.id }
        expect(other_payload['owned_by_current_user']).to eq(false)
      end

      it 'returns 400 when greentea_id is missing' do
        get '/api/v1/greenteacomments', headers: auth
        expect(response).to have_http_status(:bad_request)
        expect(response.parsed_body).to include('error')
      end
    end
  end

  describe 'POST /api/v1/greenteacomments' do
    context 'when unauthenticated' do
      it 'returns 401' do
        post '/api/v1/greenteacomments', params: { greenteacomment: { greentea_id: greentea.id, body: 'いいね' } }
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when authenticated' do
      it 'creates a comment and returns the serialized payload' do
        expect {
          post '/api/v1/greenteacomments',
               params: { greenteacomment: { greentea_id: greentea.id, body: '抹茶ティラミス最高' } },
               headers: auth
        }.to change(Greenteacomment, :count).by(1)

        expect(response).to have_http_status(:ok)
        body = response.parsed_body['data']
        expect(body).to include(
          'body' => '抹茶ティラミス最高',
          'greentea_id' => greentea.id,
          'owned_by_current_user' => true
        )
      end

      it 'returns 422 when body is blank' do
        post '/api/v1/greenteacomments',
             params: { greenteacomment: { greentea_id: greentea.id, body: '' } },
             headers: auth

        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe 'DELETE /api/v1/greenteacomments/:id' do
    let!(:own_comment) { Greenteacomment.create!(user: user, greentea: greentea, body: '自分') }
    let!(:other_comment) { Greenteacomment.create!(user: other_user, greentea: greentea, body: '他人') }

    context 'when unauthenticated' do
      it 'returns 401' do
        delete "/api/v1/greenteacomments/#{own_comment.id}"
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when authenticated' do
      it 'deletes own comment' do
        expect {
          delete "/api/v1/greenteacomments/#{own_comment.id}", headers: auth
        }.to change(Greenteacomment, :count).by(-1)

        expect(response).to have_http_status(:no_content)
      end

      it 'returns 403 when deleting another user\'s comment' do
        expect {
          delete "/api/v1/greenteacomments/#{other_comment.id}", headers: auth
        }.not_to change(Greenteacomment, :count)

        expect(response).to have_http_status(:forbidden)
      end

      it 'returns 404 for missing comment' do
        delete '/api/v1/greenteacomments/999999', headers: auth
        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
