require 'rails_helper'

RSpec.describe 'Api::V1::Genres', type: :request do
  describe 'GET /api/v1/genres' do
    let!(:genres) { create_list(:genre, 2) }

    it 'returns 200 with all genres' do
      get '/api/v1/genres'

      expect(response).to have_http_status(:ok)
      json = response.parsed_body
      expect(json['data'].size).to eq(2)
      expect(json['data'].first).to include('id', 'name')
      expect(json['data'].first['id']).to be_a(Integer)
    end
  end
end
