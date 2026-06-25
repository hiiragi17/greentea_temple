require 'rails_helper'

RSpec.describe 'Api::V1::Areas', type: :request do
  describe 'GET /api/v1/areas' do
    let!(:areas) { create_list(:area, 2) }

    it 'returns 200 with all areas' do
      get '/api/v1/areas'

      expect(response).to have_http_status(:ok)
      json = response.parsed_body
      expect(json['areas'].size).to eq(2)
      expect(json['areas'].first).to include('id', 'name')
      expect(json['areas'].first['id']).to be_a(Integer)
    end

    it 'orders areas by id ascending' do
      get '/api/v1/areas'

      ids = response.parsed_body['areas'].map { |a| a['id'] }
      expect(ids).to eq(ids.sort)
    end

    it 'does not paginate and returns all areas without meta' do
      # デフォルトの per_page(15) を超える件数を用意し、全件返ることを確認する。
      create_list(:area, 20)

      get '/api/v1/areas'

      json = response.parsed_body
      expect(json['areas'].size).to be > 15
      expect(json['areas'].size).to eq(Area.count)
      expect(json).not_to have_key('meta')
    end
  end
end
