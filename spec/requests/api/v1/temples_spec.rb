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
  end

  describe 'GET /api/v1/temples/:id' do
    let(:temple) { create(:temple, latitude: 34.9676, longitude: 135.7741) }

    it 'returns 200 with detail fields and nearby_greenteas' do
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
    end

    it 'returns 404 for missing id' do
      get '/api/v1/temples/999999'

      expect(response).to have_http_status(:not_found)
    end
  end
end
