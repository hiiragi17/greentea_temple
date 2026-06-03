require 'rails_helper'

RSpec.describe 'Api::V1::Areas', type: :request do
  describe 'GET /api/v1/areas' do
    let!(:areas) { create_list(:area, 2) }

    it 'returns 200 with all areas' do
      get '/api/v1/areas'

      expect(response).to have_http_status(:ok)
      json = response.parsed_body
      expect(json['data'].size).to eq(2)
      expect(json['data'].first).to include('id', 'name')
      expect(json['data'].first['id']).to be_a(Integer)
    end

    it 'orders areas by id ascending' do
      get '/api/v1/areas'

      ids = response.parsed_body['data'].map { |a| a['id'] }
      expect(ids).to eq(ids.sort)
    end

    it 'includes pagination meta' do
      get '/api/v1/areas'

      expect(response.parsed_body['meta']).to include(
        'current_page' => 1,
        'total_count' => 2,
        'per_page' => 15
      )
    end
  end
end
