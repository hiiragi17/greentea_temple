require 'rails_helper'

RSpec.describe 'Api::V1::Admin::Temples', type: :request do
  let(:admin) { User.create!(name: '管理者', role: :admin) }
  let(:general) { User.create!(name: '一般ユーザー', role: :general) }
  let(:admin_token) { JwtService.encode({ user_id: admin.id }) }
  let(:admin_auth) { { 'Authorization' => "Bearer #{admin_token}" } }
  let(:area) { create(:area) }

  let(:valid_attributes) do
    {
      name: '伏見稲荷大社',
      description: '千本鳥居で有名な神社',
      address: '京都市伏見区',
      access: '稲荷駅すぐ',
      phone_number: '075-641-7331',
      business_hours: '24時間',
      holiday: 'なし',
      homepage: 'https://inari.jp',
      img: 'https://example.com/images/inari.jpg',
      latitude: 34.9671,
      longitude: 135.7727,
      area_ids: [area.id]
    }
  end

  describe 'POST /api/v1/admin/temples' do
    context 'when unauthenticated' do
      it 'returns 401' do
        post '/api/v1/admin/temples', params: { temple: valid_attributes }
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when authenticated as a non-admin user' do
      let(:token) { JwtService.encode({ user_id: general.id }) }

      it 'returns 403' do
        post '/api/v1/admin/temples',
             params: { temple: valid_attributes },
             headers: { 'Authorization' => "Bearer #{token}" }
        expect(response).to have_http_status(:forbidden)
      end
    end

    context 'when authenticated as an admin' do
      it 'creates a temple and returns 201 with the detail contract' do
        expect {
          post '/api/v1/admin/temples', params: { temple: valid_attributes }, headers: admin_auth
        }.to change(Temple, :count).by(1)

        expect(response).to have_http_status(:created)
        body = response.parsed_body['temple']
        expect(body).to include('name' => '伏見稲荷大社', 'likes_count' => 0)
        expect(body['areas']).to contain_exactly('id' => area.id, 'name' => area.name)
        expect(body).to have_key('nearby_greenteas')
      end

      it 'returns 422 with errors when invalid' do
        post '/api/v1/admin/temples',
             params: { temple: valid_attributes.merge(name: '', description: '') },
             headers: admin_auth

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.parsed_body['errors']).to include('name', 'description')
      end
    end
  end

  describe 'PATCH /api/v1/admin/temples/:id' do
    let(:temple) { create(:temple) }

    it 'updates the temple and returns 200' do
      patch "/api/v1/admin/temples/#{temple.id}",
            params: { temple: { name: '更新後の神社名' } },
            headers: admin_auth

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body['temple']).to include('name' => '更新後の神社名')
      expect(temple.reload.name).to eq('更新後の神社名')
    end
  end

  describe 'DELETE /api/v1/admin/temples/:id' do
    let!(:temple) { create(:temple) }

    it 'deletes the temple and returns 204' do
      expect {
        delete "/api/v1/admin/temples/#{temple.id}", headers: admin_auth
      }.to change(Temple, :count).by(-1)

      expect(response).to have_http_status(:no_content)
    end
  end
end
