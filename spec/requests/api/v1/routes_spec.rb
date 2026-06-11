require 'rails_helper'

RSpec.describe 'Api::V1::Routes', type: :request do
  let(:user) { User.create!(name: 'ルート作成ユーザー') }
  let(:other_user) { User.create!(name: '他人') }
  let(:token) { JwtService.encode({ user_id: user.id }) }
  let(:auth) { { 'Authorization' => "Bearer #{token}" } }

  let(:greentea) { create(:greentea) }
  let(:temple) { create(:temple) }

  describe 'GET /api/v1/routes' do
    context 'when unauthenticated' do
      it 'returns 401' do
        get '/api/v1/routes'
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when authenticated' do
      it 'returns only the current user\'s routes with meta and spot_count' do
        mine = create(:route, user: user)
        create(:route_spot, route: mine, spottable: greentea, position: 1)
        create(:route, user: other_user)

        get '/api/v1/routes', headers: auth

        expect(response).to have_http_status(:ok)
        json = response.parsed_body
        ids = json['data'].map { |d| d['id'] }
        expect(ids).to eq([mine.id])
        expect(json['data'].first['spot_count']).to eq(1)
        expect(json['meta']).to include(
          'current_page' => 1,
          'total_pages' => 1,
          'total_count' => 1,
          'per_page' => 15
        )
      end
    end
  end

  describe 'GET /api/v1/routes/:id' do
    it 'returns 401 when unauthenticated' do
      route = create(:route, user: user)
      get "/api/v1/routes/#{route.id}"
      expect(response).to have_http_status(:unauthorized)
    end

    it 'returns the route with ordered spots and distance_to_next_meters' do
      route = create(:route, user: user)
      create(:route_spot, route: route, spottable: temple, position: 1, transport: :walk)
      create(:route_spot, route: route, spottable: greentea, position: 2)

      get "/api/v1/routes/#{route.id}", headers: auth

      expect(response).to have_http_status(:ok)
      spots = response.parsed_body['data']['spots']
      expect(spots.map { |s| s['position'] }).to eq([1, 2])
      expect(spots.map { |s| s['spot_type'] }).to eq(%w[temple greentea])
      expect(spots.first['transport']).to eq('walk')
      expect(spots.first['name']).to eq(temple.name)
      expect(spots.first['distance_to_next_meters']).to be_a(Integer)
      expect(spots.last['distance_to_next_meters']).to be_nil
    end

    it 'returns 404 for another user\'s route' do
      route = create(:route, user: other_user)
      get "/api/v1/routes/#{route.id}", headers: auth
      expect(response).to have_http_status(:not_found)
    end
  end

  describe 'POST /api/v1/routes' do
    let(:valid_params) do
      {
        route: {
          name: '祇園抹茶巡り',
          description: '神社とお茶屋さんを巡る',
          spots: [
            { spot_type: 'temple', spot_id: temple.id, transport: 'walk' },
            { spot_type: 'greentea', spot_id: greentea.id }
          ]
        }
      }
    end

    it 'returns 401 when unauthenticated' do
      post '/api/v1/routes', params: valid_params
      expect(response).to have_http_status(:unauthorized)
    end

    it 'creates a route with ordered spots and returns 201' do
      expect {
        post '/api/v1/routes', params: valid_params, headers: auth
      }.to change(Route, :count).by(1).and change(RouteSpot, :count).by(2)

      expect(response).to have_http_status(:created)
      data = response.parsed_body['data']
      expect(data['name']).to eq('祇園抹茶巡り')
      expect(data['spots'].map { |s| s['position'] }).to eq([1, 2])
      expect(data['spots'].first['spot_type']).to eq('temple')

      expect(Route.last.user).to eq(user)
    end

    it 'returns 422 when name is missing' do
      params = valid_params.deep_dup
      params[:route][:name] = ''
      expect {
        post '/api/v1/routes', params: params, headers: auth
      }.not_to change(Route, :count)
      expect(response).to have_http_status(:unprocessable_entity)
    end

    it 'returns 422 for an invalid spot_type' do
      params = valid_params.deep_dup
      params[:route][:spots] = [{ spot_type: 'castle', spot_id: 1 }]
      expect {
        post '/api/v1/routes', params: params, headers: auth
      }.not_to change(Route, :count)
      expect(response).to have_http_status(:unprocessable_entity)
    end

    it 'returns 422 for a non-existent spot' do
      params = valid_params.deep_dup
      params[:route][:spots] = [{ spot_type: 'greentea', spot_id: 999_999 }]
      expect {
        post '/api/v1/routes', params: params, headers: auth
      }.not_to change(Route, :count)
      expect(response).to have_http_status(:unprocessable_entity)
    end

    it 'returns 422 for an invalid transport' do
      params = valid_params.deep_dup
      params[:route][:spots] = [{ spot_type: 'greentea', spot_id: greentea.id, transport: 'teleport' }]
      expect {
        post '/api/v1/routes', params: params, headers: auth
      }.not_to change(Route, :count)
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe 'PATCH /api/v1/routes/:id' do
    it 'replaces the route name and spots' do
      route = create(:route, user: user, name: '旧ルート')
      create(:route_spot, route: route, spottable: greentea, position: 1)

      patch "/api/v1/routes/#{route.id}",
            params: {
              route: {
                name: '新ルート',
                spots: [{ spot_type: 'temple', spot_id: temple.id, transport: 'train' }]
              }
            },
            headers: auth

      expect(response).to have_http_status(:ok)
      route.reload
      expect(route.name).to eq('新ルート')
      expect(route.route_spots.map(&:spottable)).to eq([temple])
      expect(route.route_spots.first.transport).to eq('train')
    end

    it 'returns 404 for another user\'s route' do
      route = create(:route, user: other_user)
      patch "/api/v1/routes/#{route.id}", params: { route: { name: 'x' } }, headers: auth
      expect(response).to have_http_status(:not_found)
    end
  end

  describe 'DELETE /api/v1/routes/:id' do
    it 'returns 401 when unauthenticated' do
      route = create(:route, user: user)
      delete "/api/v1/routes/#{route.id}"
      expect(response).to have_http_status(:unauthorized)
    end

    it 'deletes the current user\'s route and its spots' do
      route = create(:route, user: user)
      create(:route_spot, route: route, spottable: greentea, position: 1)

      expect {
        delete "/api/v1/routes/#{route.id}", headers: auth
      }.to change(Route, :count).by(-1).and change(RouteSpot, :count).by(-1)

      expect(response).to have_http_status(:no_content)
    end

    it 'returns 404 for another user\'s route' do
      route = create(:route, user: other_user)
      expect {
        delete "/api/v1/routes/#{route.id}", headers: auth
      }.not_to change(Route, :count)
      expect(response).to have_http_status(:not_found)
    end
  end
end
