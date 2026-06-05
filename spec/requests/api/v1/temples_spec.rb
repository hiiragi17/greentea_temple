require 'rails_helper'

RSpec.describe 'Api::V1::Temples', type: :request do
  describe 'GET /api/v1/temples' do
    let!(:temples) { create_list(:temple, 3) }

    it 'returns 200 with data and meta' do
      get '/api/v1/temples'

      expect(response).to have_http_status(:ok)
      json = response.parsed_body
      expect(json['data'].size).to eq(3)
      expect(json['meta']).to include(
        'current_page' => 1,
        'total_count' => 3,
        'per_page' => 15
      )
    end

    it 'returns flat snake_case spot fields' do
      get '/api/v1/temples'

      attrs = response.parsed_body['data'].first
      expect(attrs).to include(
        'id', 'name', 'address', 'access', 'business_hours', 'holiday',
        'latitude', 'longitude', 'img', 'like_count', 'liked_by_current_user'
      )
    end

    it 'filters by q[areas_id_eq]' do
      area = create(:area)
      target = create(:temple)
      create(:temple_area, temple: target, area: area)

      get '/api/v1/temples', params: { q: { areas_id_eq: area.id } }

      ids = response.parsed_body['data'].map { |d| d['id'] }
      expect(ids).to eq([target.id])
    end

    # Web 既存検索フォームの ransack キーが allowlist で通ることの回帰テスト
    it 'accepts q[name_or_description_or_address_or_access_cont] (legacy web key)' do
      target = create(:temple, description: '紅葉の名所として知られる古刹')

      get '/api/v1/temples', params: { q: { name_or_description_or_address_or_access_cont: '紅葉の名所' } }

      ids = response.parsed_body['data'].map { |d| d['id'] }
      expect(ids).to eq([target.id])
    end

    it 'accepts q[temple_areas_area_id_eq_any] (legacy web key)' do
      area = create(:area)
      target = create(:temple)
      create(:temple_area, temple: target, area: area)

      get '/api/v1/temples', params: { q: { temple_areas_area_id_eq_any: [area.id] } }

      ids = response.parsed_body['data'].map { |d| d['id'] }
      expect(ids).to eq([target.id])
    end

    it 'reflects liked_by_current_user when authenticated' do
      user = User.create!(name: '神社いいね回帰テスト')
      liked = temples.first
      TempleLike.create!(user: user, temple: liked)
      token = JwtService.encode({ user_id: user.id })

      get '/api/v1/temples', headers: { 'Authorization' => "Bearer #{token}" }

      liked_payload = response.parsed_body['data'].find { |d| d['id'] == liked.id }
      unliked_payload = response.parsed_body['data'].find { |d| d['id'] != liked.id }
      expect(liked_payload['liked_by_current_user']).to eq(true)
      expect(unliked_payload['liked_by_current_user']).to eq(false)
    end
  end

  describe 'GET /api/v1/temples/:id' do
    let(:temple) { create(:temple, latitude: 34.9676, longitude: 135.7741) }

    it 'returns 200 with detail fields and nearby_greenteas in meters' do
      near = create(:greentea, latitude: 34.96770, longitude: 135.77410)

      get "/api/v1/temples/#{temple.id}"

      expect(response).to have_http_status(:ok)
      attrs = response.parsed_body['data']
      expect(attrs).to include(
        'id', 'name', 'description', 'address', 'access', 'business_hours',
        'holiday', 'phone_number', 'homepage', 'latitude', 'longitude', 'img',
        'like_count', 'liked_by_current_user', 'areas', 'nearby_greenteas'
      )
      expect(attrs['nearby_greenteas'].map { |g| g['id'] }).to include(near.id)
      attrs['nearby_greenteas'].each do |g|
        expect(g).to include('id', 'name', 'latitude', 'longitude', 'distance_meters')
        expect(g['distance_meters']).to be_a(Integer)
      end

      origin = Geokit::LatLng.new(temple.latitude, temple.longitude)
      expected = (origin.distance_to(Geokit::LatLng.new(near.latitude, near.longitude), units: :kms) * 1000).round
      near_payload = attrs['nearby_greenteas'].find { |g| g['id'] == near.id }
      expect(near_payload['distance_meters']).to be_within(2).of(expected)
    end

    it 'returns 404 with error body for missing id' do
      get '/api/v1/temples/999999'

      expect(response).to have_http_status(:not_found)
      expect(response.parsed_body).to eq('error' => 'Not Found')
    end

    it 'returns liked_by_current_user=true when the authenticated user liked it' do
      user = User.create!(name: '神社いいねユーザー')
      TempleLike.create!(user: user, temple: temple)
      token = JwtService.encode({ user_id: user.id })

      get "/api/v1/temples/#{temple.id}", headers: { 'Authorization' => "Bearer #{token}" }

      expect(response.parsed_body['data']['liked_by_current_user']).to eq(true)
    end
  end
end
