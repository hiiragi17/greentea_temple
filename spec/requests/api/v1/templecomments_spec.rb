require 'rails_helper'

RSpec.describe 'Api::V1::Templecomments', type: :request do
  let(:user) { User.create!(name: '口コミ投稿者') }
  let(:other_user) { User.create!(name: '他人') }
  let(:temple) { create(:temple) }
  let(:token) { JwtService.encode({ user_id: user.id }) }
  let(:auth) { { 'Authorization' => "Bearer #{token}" } }

  describe 'GET /api/v1/templecomments' do
    context 'when unauthenticated' do
      it 'returns 401' do
        get '/api/v1/templecomments', params: { temple_id: temple.id }
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when authenticated' do
      it 'returns comments for the given temple, newest first' do
        own = Templecomment.create!(user: user, temple: temple, body: '自分の口コミ', created_at: 1.day.ago)
        other = Templecomment.create!(user: other_user, temple: temple, body: '他人の口コミ', created_at: 1.hour.ago)
        Templecomment.create!(user: user, temple: create(:temple), body: '別社')

        get '/api/v1/templecomments', params: { temple_id: temple.id }, headers: auth

        expect(response).to have_http_status(:ok)
        json = response.parsed_body
        expect(json['meta']).to include('current_page', 'total_pages', 'total_count')
        expect(json['meta']).not_to include('per_page')
        ids = json['data'].map { |d| d['id'] }
        expect(ids).to eq([other.id, own.id])

        own_payload = json['data'].find { |d| d['id'] == own.id }
        expect(own_payload['owned_by_current_user']).to eq(true)
      end

      it 'returns 400 when temple_id is missing' do
        get '/api/v1/templecomments', headers: auth
        expect(response).to have_http_status(:bad_request)
        expect(response.parsed_body).to include('error')
      end
    end
  end

  describe 'POST /api/v1/templecomments' do
    context 'when unauthenticated' do
      it 'returns 401' do
        post '/api/v1/templecomments', params: { templecomment: { temple_id: temple.id, body: '良い' } }
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when authenticated' do
      it 'creates a comment' do
        expect {
          post '/api/v1/templecomments',
               params: { templecomment: { temple_id: temple.id, body: '荘厳' } },
               headers: auth
        }.to change(Templecomment, :count).by(1)

        expect(response).to have_http_status(:ok)
        expect(response.parsed_body['data']).to include(
          'body' => '荘厳',
          'temple_id' => temple.id,
          'owned_by_current_user' => true
        )
      end

      it 'returns 422 when body is blank' do
        post '/api/v1/templecomments',
             params: { templecomment: { temple_id: temple.id, body: '' } },
             headers: auth

        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe 'DELETE /api/v1/templecomments/:id' do
    let!(:own_comment) { Templecomment.create!(user: user, temple: temple, body: '自分') }
    let!(:other_comment) { Templecomment.create!(user: other_user, temple: temple, body: '他人') }

    context 'when unauthenticated' do
      it 'returns 401' do
        delete "/api/v1/templecomments/#{own_comment.id}"
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when authenticated' do
      it 'deletes own comment' do
        expect {
          delete "/api/v1/templecomments/#{own_comment.id}", headers: auth
        }.to change(Templecomment, :count).by(-1)

        expect(response).to have_http_status(:no_content)
      end

      it 'returns 403 when deleting another user\'s comment' do
        expect {
          delete "/api/v1/templecomments/#{other_comment.id}", headers: auth
        }.not_to change(Templecomment, :count)

        expect(response).to have_http_status(:forbidden)
      end

      it 'returns 404 for missing comment' do
        delete '/api/v1/templecomments/999999', headers: auth
        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
