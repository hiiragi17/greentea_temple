require 'rails_helper'

RSpec.describe 'Api::V1::Admin::Greenteas', type: :request do
  let(:admin) { User.create!(name: '管理者', role: :admin) }
  let(:general) { User.create!(name: '一般ユーザー', role: :general) }
  let(:admin_token) { JwtService.encode({ user_id: admin.id }) }
  let(:admin_auth) { { 'Authorization' => "Bearer #{admin_token}" } }
  let(:genre) { create(:genre) }

  let(:valid_attributes) do
    {
      name: '茶寮都路里 祇園本店',
      description: '美味しい抹茶パフェの店',
      address: '京都市東山区',
      access: '祇園四条駅から徒歩5分',
      phone_number: '075-561-2257',
      business_hours: '10:00-21:00',
      holiday: '不定休',
      homepage: 'https://example.com/tsujiri',
      closed: false,
      img: 'https://example.com/images/tsujiri.jpg',
      latitude: 35.0036,
      longitude: 135.7752,
      genre_ids: [genre.id]
    }
  end

  describe 'POST /api/v1/admin/greenteas' do
    context 'when unauthenticated' do
      it 'returns 401' do
        post '/api/v1/admin/greenteas', params: { greentea: valid_attributes }
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when authenticated as a non-admin user' do
      let(:token) { JwtService.encode({ user_id: general.id }) }

      it 'returns 403' do
        post '/api/v1/admin/greenteas',
             params: { greentea: valid_attributes },
             headers: { 'Authorization' => "Bearer #{token}" }
        expect(response).to have_http_status(:forbidden)
      end
    end

    context 'when authenticated as an admin' do
      it 'creates a greentea and returns 201 with the detail contract' do
        expect {
          post '/api/v1/admin/greenteas', params: { greentea: valid_attributes }, headers: admin_auth
        }.to change(Greentea, :count).by(1)

        expect(response).to have_http_status(:created)
        body = response.parsed_body['greentea']
        expect(body).to include(
          'name' => '茶寮都路里 祇園本店',
          'closed' => false,
          'likes_count' => 0,
          'img' => 'https://example.com/images/tsujiri.jpg'
        )
        expect(body['genres']).to contain_exactly('id' => genre.id, 'name' => genre.name)
        expect(body).to have_key('nearby_temples')
      end

      it 'returns 422 with errors when invalid' do
        post '/api/v1/admin/greenteas',
             params: { greentea: valid_attributes.merge(name: '', description: '') },
             headers: admin_auth

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.parsed_body['errors']).to include('name', 'description')
      end
    end
  end

  describe 'PATCH /api/v1/admin/greenteas/:id' do
    let(:greentea) { create(:greentea) }

    it 'updates the greentea and returns 200' do
      patch "/api/v1/admin/greenteas/#{greentea.id}",
            params: { greentea: { name: '更新後の店名', closed: true } },
            headers: admin_auth

      expect(response).to have_http_status(:ok)
      body = response.parsed_body['greentea']
      expect(body).to include('name' => '更新後の店名', 'closed' => true)
      expect(greentea.reload.name).to eq('更新後の店名')
    end

    it 'returns 403 for a non-admin user' do
      token = JwtService.encode({ user_id: general.id })
      patch "/api/v1/admin/greenteas/#{greentea.id}",
            params: { greentea: { name: 'x' } },
            headers: { 'Authorization' => "Bearer #{token}" }
      expect(response).to have_http_status(:forbidden)
    end
  end

  describe 'DELETE /api/v1/admin/greenteas/:id' do
    let!(:greentea) { create(:greentea) }

    it 'deletes the greentea and returns 204' do
      expect {
        delete "/api/v1/admin/greenteas/#{greentea.id}", headers: admin_auth
      }.to change(Greentea, :count).by(-1)

      expect(response).to have_http_status(:no_content)
    end

    it 'returns 401 when unauthenticated' do
      delete "/api/v1/admin/greenteas/#{greentea.id}"
      expect(response).to have_http_status(:unauthorized)
    end

    it 'also removes route spots referencing the greentea (no orphan rows)' do
      route = create(:route)
      route_spot = create(:route_spot, route: route, spottable: greentea, position: 2)

      expect {
        delete "/api/v1/admin/greenteas/#{greentea.id}", headers: admin_auth
      }.to change(RouteSpot, :count).by(-1)

      expect(RouteSpot.exists?(route_spot.id)).to be(false)
    end
  end
end
