require 'rails_helper'

RSpec.describe 'Api::V1::Greenteas', type: :request do
  describe 'GET /api/v1/greenteas' do
    let!(:greenteas) { create_list(:greentea, 3) }

    it 'returns 200 with greenteas and meta' do
      get '/api/v1/greenteas'

      expect(response).to have_http_status(:ok)
      json = response.parsed_body
      expect(json['greenteas']).to be_an(Array)
      expect(json['greenteas'].size).to eq(3)
      expect(json['meta']).to include(
        'current_page' => 1,
        'total_count' => 3
      )
      expect(json['meta']['total_pages']).to eq(1)
      expect(json['meta']).not_to include('per_page')
    end

    it 'returns flat snake_case spot fields' do
      get '/api/v1/greenteas'

      attrs = response.parsed_body['greenteas'].first
      expect(attrs).to include(
        'id', 'name', 'description', 'address', 'access', 'phone_number',
        'business_hours', 'holiday', 'homepage', 'closed', 'img',
        'latitude', 'longitude', 'genres', 'likes_count'
      )
      expect(attrs['id']).to be_a(Integer)
      # 一覧には liked_by_current_user を含めない（詳細のみ）
      expect(attrs).not_to include('liked_by_current_user')
    end

    it 'paginates with page / per_page params' do
      get '/api/v1/greenteas', params: { per_page: 2, page: 2 }

      json = response.parsed_body
      expect(json['greenteas'].size).to eq(1)
      expect(json['meta']).to include('current_page' => 2, 'total_pages' => 2)
    end

    it 'filters by q[name_cont] (Ransack allowlist)' do
      target = create(:greentea, name: '宇治抹茶パフェ専門店')

      get '/api/v1/greenteas', params: { q: { name_cont: '宇治抹茶' } }

      ids = response.parsed_body['greenteas'].map { |d| d['id'] }
      expect(ids).to eq([target.id])
    end

    it 'filters by q[genres_id_eq]' do
      genre = create(:genre)
      target = create(:greentea)
      create(:greentea_genre, greentea: target, genre: genre)

      get '/api/v1/greenteas', params: { q: { genres_id_eq: genre.id } }

      ids = response.parsed_body['greenteas'].map { |d| d['id'] }
      expect(ids).to eq([target.id])
    end

    # Web 既存検索フォームの ransack キーが allowlist で通ることの回帰テスト
    it 'accepts q[name_or_description_or_address_or_access_cont] (legacy web key)' do
      target = create(:greentea, description: 'とろける宇治抹茶のティラミス')

      get '/api/v1/greenteas', params: { q: { name_or_description_or_address_or_access_cont: 'とろける宇治抹茶' } }

      ids = response.parsed_body['greenteas'].map { |d| d['id'] }
      expect(ids).to eq([target.id])
    end

    it 'accepts q[greentea_genres_genre_id_eq_any] (legacy web key)' do
      genre = create(:genre)
      target = create(:greentea)
      create(:greentea_genre, greentea: target, genre: genre)

      get '/api/v1/greenteas', params: { q: { greentea_genres_genre_id_eq_any: [genre.id] } }

      ids = response.parsed_body['greenteas'].map { |d| d['id'] }
      expect(ids).to eq([target.id])
    end

    it 'returns likes_count aggregated per record' do
      liked = greenteas.first
      user_a = create(:user)
      user_b = create(:user)
      GreenteaLike.create!(user: user_a, greentea: liked)
      GreenteaLike.create!(user: user_b, greentea: liked)

      get '/api/v1/greenteas'

      payload = response.parsed_body['greenteas'].find { |d| d['id'] == liked.id }
      expect(payload['likes_count']).to eq(2)
    end

    it 'normalizes closed to a boolean' do
      get '/api/v1/greenteas'

      closed_values = response.parsed_body['greenteas'].map { |d| d['closed'] }
      expect(closed_values).to all(be_in([true, false]))
    end
  end

  describe 'GET /api/v1/greenteas/:id' do
    let(:greentea) { create(:greentea, latitude: 34.9676, longitude: 135.7741) }

    it 'returns 200 with detail fields' do
      get "/api/v1/greenteas/#{greentea.id}"

      expect(response).to have_http_status(:ok)
      attrs = response.parsed_body['greentea']
      expect(attrs).to include(
        'id', 'name', 'description', 'address', 'access', 'business_hours',
        'holiday', 'phone_number', 'homepage', 'closed', 'latitude', 'longitude', 'img',
        'likes_count', 'liked_by_current_user', 'genres', 'nearby_temples', 'comments'
      )
      expect(attrs['id']).to eq(greentea.id)
    end

    it 'includes comments with author and ownership flag' do
      author = create(:user)
      create(:greenteacomment, greentea: greentea, user: author, body: '美味しかった')

      get "/api/v1/greenteas/#{greentea.id}"

      comment = response.parsed_body['greentea']['comments'].first
      expect(comment).to include('id', 'body', 'created_at', 'owned_by_current_user')
      expect(comment['user']).to include('id' => author.id, 'name' => author.name)
      expect(comment['owned_by_current_user']).to eq(false)
    end

    it 'returns liked_by_current_user=true when the authenticated user liked it' do
      user = User.create!(name: '詳細いいねユーザー')
      GreenteaLike.create!(user: user, greentea: greentea)
      token = JwtService.encode({ user_id: user.id })

      get "/api/v1/greenteas/#{greentea.id}", headers: { 'Authorization' => "Bearer #{token}" }

      expect(response.parsed_body['greentea']['liked_by_current_user']).to eq(true)
    end

    it 'includes nearby_temples sorted by distance ascending with meter values' do
      near = create(:temple, latitude: 34.96770, longitude: 135.77410)
      mid  = create(:temple, latitude: 34.96900, longitude: 135.77410)

      get "/api/v1/greenteas/#{greentea.id}"

      nearby = response.parsed_body['greentea']['nearby_temples']
      expect(nearby.map { |t| t['id'] }).to eq([near.id, mid.id])
      nearby.each do |t|
        expect(t).to include('id', 'name', 'latitude', 'longitude', 'distance_meters')
        expect(t['distance_meters']).to be_a(Integer)
      end

      origin = Geokit::LatLng.new(greentea.latitude, greentea.longitude)
      expected_near = (origin.distance_to(Geokit::LatLng.new(near.latitude, near.longitude), units: :kms) * 1000).round
      expected_mid  = (origin.distance_to(Geokit::LatLng.new(mid.latitude, mid.longitude), units: :kms) * 1000).round
      expect(nearby[0]['distance_meters']).to be_within(2).of(expected_near)
      expect(nearby[1]['distance_meters']).to be_within(2).of(expected_mid)

      distances = nearby.map { |t| t['distance_meters'] }
      expect(distances).to eq(distances.sort)
    end

    it 'returns 404 with error body for missing id' do
      get '/api/v1/greenteas/999999'

      expect(response).to have_http_status(:not_found)
      expect(response.parsed_body).to eq('error' => 'Not Found')
    end
  end
end
