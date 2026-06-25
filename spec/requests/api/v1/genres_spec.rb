require 'rails_helper'

RSpec.describe 'Api::V1::Genres', type: :request do
  describe 'GET /api/v1/genres' do
    let!(:genres) { create_list(:genre, 2) }

    it 'returns 200 with all genres' do
      get '/api/v1/genres'

      expect(response).to have_http_status(:ok)
      json = response.parsed_body
      expect(json['genres'].size).to eq(2)
      expect(json['genres'].first).to include('id', 'name')
      expect(json['genres'].first['id']).to be_a(Integer)
    end

    it 'orders genres by id ascending' do
      get '/api/v1/genres'

      ids = response.parsed_body['genres'].map { |g| g['id'] }
      expect(ids).to eq(ids.sort)
    end

    it 'does not paginate and returns all genres without meta' do
      # デフォルトの per_page(15) を超える件数を用意し、全件返ることを確認する。
      create_list(:genre, 20)

      get '/api/v1/genres'

      json = response.parsed_body
      expect(json['genres'].size).to be > 15
      expect(json['genres'].size).to eq(Genre.count)
      expect(json).not_to have_key('meta')
    end
  end
end
