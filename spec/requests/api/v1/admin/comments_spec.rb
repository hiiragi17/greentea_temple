require 'rails_helper'

RSpec.describe 'Api::V1::Admin::Comments', type: :request do
  let(:admin) { User.create!(name: '管理者', role: :admin) }
  let(:general) { User.create!(name: '一般ユーザー', role: :general) }
  let(:commenter) { User.create!(name: '投稿者') }
  let(:admin_token) { JwtService.encode({ user_id: admin.id }) }
  let(:admin_auth) { { 'Authorization' => "Bearer #{admin_token}" } }

  let(:greentea) { create(:greentea) }
  let(:temple) { create(:temple) }
  let!(:greentea_comment) { create(:greenteacomment, user: commenter, greentea: greentea) }
  let!(:temple_comment) { create(:templecomment, user: commenter, temple: temple) }

  describe 'GET /api/v1/admin/comments' do
    it 'returns 401 when unauthenticated' do
      get '/api/v1/admin/comments'
      expect(response).to have_http_status(:unauthorized)
    end

    it 'returns 403 for a non-admin user' do
      token = JwtService.encode({ user_id: general.id })
      get '/api/v1/admin/comments', headers: { 'Authorization' => "Bearer #{token}" }
      expect(response).to have_http_status(:forbidden)
    end

    it 'lists greentea and temple comments with meta' do
      get '/api/v1/admin/comments', headers: admin_auth

      expect(response).to have_http_status(:ok)
      json = response.parsed_body
      types = json['comments'].map { |c| c['type'] }
      expect(types).to contain_exactly('greentea', 'temple')
      expect(json['meta']).to include('current_page' => 1, 'total_pages' => 1, 'total_count' => 2)
    end

    it 'filters by type' do
      get '/api/v1/admin/comments', params: { type: 'greentea' }, headers: admin_auth

      expect(response).to have_http_status(:ok)
      comments = response.parsed_body['comments']
      expect(comments.map { |c| c['type'] }).to all(eq('greentea'))
      expect(comments.first).to include('greentea_id' => greentea.id)
    end
  end

  describe 'DELETE /api/v1/admin/greenteacomments/:id' do
    it "deletes another user's comment and returns 204" do
      expect {
        delete "/api/v1/admin/greenteacomments/#{greentea_comment.id}", headers: admin_auth
      }.to change(Greenteacomment, :count).by(-1)

      expect(response).to have_http_status(:no_content)
    end

    it 'returns 403 for a non-admin user' do
      token = JwtService.encode({ user_id: general.id })
      delete "/api/v1/admin/greenteacomments/#{greentea_comment.id}",
             headers: { 'Authorization' => "Bearer #{token}" }
      expect(response).to have_http_status(:forbidden)
    end
  end

  describe 'DELETE /api/v1/admin/templecomments/:id' do
    it "deletes another user's comment and returns 204" do
      expect {
        delete "/api/v1/admin/templecomments/#{temple_comment.id}", headers: admin_auth
      }.to change(Templecomment, :count).by(-1)

      expect(response).to have_http_status(:no_content)
    end

    it 'returns 403 for a non-admin user' do
      token = JwtService.encode({ user_id: general.id })
      delete "/api/v1/admin/templecomments/#{temple_comment.id}",
             headers: { 'Authorization' => "Bearer #{token}" }
      expect(response).to have_http_status(:forbidden)
    end
  end
end
