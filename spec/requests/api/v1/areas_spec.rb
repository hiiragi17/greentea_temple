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
  end
end
