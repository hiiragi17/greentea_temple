require 'rails_helper'

RSpec.describe 'Api::V1::Routes', type: :request do
  let(:user) { User.create!(name: 'ルート作成ユーザー') }
  let(:other_user) { User.create!(name: '他人') }
  let(:token) { JwtService.encode({ user_id: user.id }) }
  let(:auth) { { 'Authorization' => "Bearer #{token}" } }

  let(:greentea) { create(:greentea) }
  let(:temple) { create(:temple) }

  # spots: [{ spottable:, transport: }] を順序付きで持つ Route を 1 件作る。
  def create_route_for(owner, spots)
    Route.create!(
      user: owner,
      name: 'テストルート',
      route_spots: spots.each_with_index.map { |attrs, i| RouteSpot.new(position: i + 1, **attrs) }
    )
  end

  describe 'GET /api/v1/routes' do
    context 'when unauthenticated' do
      it 'returns 401 with a JSON error body' do
        get '/api/v1/routes'
        expect(response).to have_http_status(:unauthorized)
        expect(response.media_type).to eq('application/json')
        expect(response.parsed_body['error']).to be_present
      end
    end

    context 'when authenticated' do
      it 'returns only the current user\'s routes with meta and spot_count' do
        mine = create_route_for(user, [{ spottable: greentea }])
        create_route_for(other_user, [{ spottable: greentea }])

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
      route = create_route_for(user, [{ spottable: greentea }])
      get "/api/v1/routes/#{route.id}"
      expect(response).to have_http_status(:unauthorized)
    end

    it 'returns the route with ordered spots and distance_to_next_meters' do
      spots = [{ spottable: temple, transport: :walk }, { spottable: greentea }]
      route = create_route_for(user, spots)

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
      route = create_route_for(other_user, [{ spottable: greentea }])
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

    it 'allows duplicate spots in the same route' do
      params = valid_params.deep_dup
      params[:route][:spots] = [
        { spot_type: 'greentea', spot_id: greentea.id },
        { spot_type: 'greentea', spot_id: greentea.id }
      ]
      expect {
        post '/api/v1/routes', params: params, headers: auth
      }.to change(RouteSpot, :count).by(2)
      expect(response).to have_http_status(:created)
    end

    it 'returns 422 when name is missing' do
      params = valid_params.deep_dup
      params[:route][:name] = ''
      expect {
        post '/api/v1/routes', params: params, headers: auth
      }.not_to change(Route, :count)
      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.media_type).to eq('application/json')
      expect(response.parsed_body['error']).to be_present
    end

    it 'returns 422 when spots are empty' do
      params = valid_params.deep_dup
      params[:route][:spots] = []
      expect {
        post '/api/v1/routes', params: params, headers: auth
      }.not_to change(Route, :count)
      expect(response).to have_http_status(:unprocessable_entity)
    end

    it 'returns 422 when the spots key is absent' do
      expect {
        post '/api/v1/routes', params: { route: { name: 'スポットなし' } }, headers: auth
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
    it 'returns 401 when unauthenticated' do
      route = create_route_for(user, [{ spottable: greentea }])
      patch "/api/v1/routes/#{route.id}", params: { route: { name: 'x' } }
      expect(response).to have_http_status(:unauthorized)
    end

    it 'replaces the route name and spots' do
      route = create_route_for(user, [{ spottable: greentea }])

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

    it 'updates only scalar fields and preserves spots when the spots key is omitted' do
      route = create_route_for(user, [{ spottable: greentea }, { spottable: temple }])

      patch "/api/v1/routes/#{route.id}",
            params: { route: { description: '説明だけ更新' } },
            headers: auth

      expect(response).to have_http_status(:ok)
      route.reload
      expect(route.description).to eq('説明だけ更新')
      expect(route.name).to eq('テストルート')
      expect(route.route_spots.count).to eq(2)
    end

    it 'returns 422 and keeps existing spots when updating to empty spots' do
      route = create_route_for(user, [{ spottable: greentea }])

      patch "/api/v1/routes/#{route.id}",
            params: { route: { name: 'x', spots: [] } },
            headers: auth

      expect(response).to have_http_status(:unprocessable_entity)
      expect(route.reload.route_spots.count).to eq(1)
    end

    it 'returns 404 for another user\'s route' do
      route = create_route_for(other_user, [{ spottable: greentea }])
      patch "/api/v1/routes/#{route.id}", params: { route: { name: 'x' } }, headers: auth
      expect(response).to have_http_status(:not_found)
    end
  end

  describe 'DELETE /api/v1/routes/:id' do
    it 'returns 401 when unauthenticated' do
      route = create_route_for(user, [{ spottable: greentea }])
      delete "/api/v1/routes/#{route.id}"
      expect(response).to have_http_status(:unauthorized)
    end

    it 'deletes the current user\'s route and its spots' do
      route = create_route_for(user, [{ spottable: greentea }])

      expect {
        delete "/api/v1/routes/#{route.id}", headers: auth
      }.to change(Route, :count).by(-1).and change(RouteSpot, :count).by(-1)

      expect(response).to have_http_status(:no_content)
    end

    it 'returns 404 for another user\'s route' do
      route = create_route_for(other_user, [{ spottable: greentea }])
      expect {
        delete "/api/v1/routes/#{route.id}", headers: auth
      }.not_to change(Route, :count)
      expect(response).to have_http_status(:not_found)
    end
  end
end
