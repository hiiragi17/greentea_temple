require 'rails_helper'

RSpec.describe 'Api::V1::Nearby', type: :request do
  describe 'GET /api/v1/nearby' do
    # 京都駅近傍を原点に検証する
    let(:origin_lat) { 34.9676 }
    let(:origin_lng) { 135.7741 }

    context 'with valid lat / lng' do
      let!(:near_greentea) { create(:greentea, latitude: 34.96770, longitude: 135.77410) }
      let!(:near_temple) { create(:temple, latitude: 34.96780, longitude: 135.77420) }
      let!(:far_greentea) { create(:greentea, latitude: 35.10000, longitude: 135.90000) }
      let!(:far_temple) { create(:temple, latitude: 35.10000, longitude: 135.90000) }

      it 'returns 200 with greenteas and temples arrays' do
        get '/api/v1/nearby', params: { lat: origin_lat, lng: origin_lng }

        expect(response).to have_http_status(:ok)
        json = response.parsed_body
        expect(json).to include('greenteas', 'temples')
      end

      it 'includes nearby spots within default 1.5km radius and excludes far ones' do
        get '/api/v1/nearby', params: { lat: origin_lat, lng: origin_lng }

        json = response.parsed_body
        greentea_ids = json['greenteas'].map { |r| r['id'] }
        temple_ids = json['temples'].map { |r| r['id'] }
        expect(greentea_ids).to include(near_greentea.id)
        expect(greentea_ids).not_to include(far_greentea.id)
        expect(temple_ids).to include(near_temple.id)
        expect(temple_ids).not_to include(far_temple.id)
      end

      it 'returns flat snake_case fields with integer distance_meters' do
        get '/api/v1/nearby', params: { lat: origin_lat, lng: origin_lng }

        json = response.parsed_body
        json['greenteas'].each do |g|
          expect(g).to include('id', 'name', 'latitude', 'longitude', 'distance_meters')
          expect(g['distance_meters']).to be_a(Integer)
        end
        json['temples'].each do |t|
          expect(t).to include('id', 'name', 'latitude', 'longitude', 'distance_meters')
          expect(t['distance_meters']).to be_a(Integer)
        end
      end

      it 'orders each array by distance_meters ascending' do
        # 既存 near と原点の間に位置するもう一件を追加して順序を確認
        nearer_greentea = create(:greentea, latitude: origin_lat, longitude: origin_lng)
        nearer_temple = create(:temple, latitude: origin_lat, longitude: origin_lng)

        get '/api/v1/nearby', params: { lat: origin_lat, lng: origin_lng }

        json = response.parsed_body
        greentea_distances = json['greenteas'].map { |g| g['distance_meters'] }
        temple_distances = json['temples'].map { |t| t['distance_meters'] }
        expect(greentea_distances).to eq(greentea_distances.sort)
        expect(temple_distances).to eq(temple_distances.sort)
        expect(json['greenteas'].first['id']).to eq(nearer_greentea.id)
        expect(json['temples'].first['id']).to eq(nearer_temple.id)
      end

      it 'respects custom radius parameter' do
        # 5km 弱離れた地点を作成し、radius=1.5 では含まれず radius=10 では含まれることを確認
        mid_greentea = create(:greentea, latitude: 35.00000, longitude: 135.80000)

        get '/api/v1/nearby', params: { lat: origin_lat, lng: origin_lng, radius: 1.5 }
        expect(response.parsed_body['greenteas'].map { |r| r['id'] }).not_to include(mid_greentea.id)

        get '/api/v1/nearby', params: { lat: origin_lat, lng: origin_lng, radius: 10 }
        expect(response.parsed_body['greenteas'].map { |r| r['id'] }).to include(mid_greentea.id)
      end

      it 'computes distance_meters consistent with Geokit' do
        get '/api/v1/nearby', params: { lat: origin_lat, lng: origin_lng }

        origin = Geokit::LatLng.new(origin_lat, origin_lng)
        expected = (origin.distance_to(Geokit::LatLng.new(near_greentea.latitude, near_greentea.longitude)) * 1000).round
        actual = response.parsed_body['greenteas'].find { |g| g['id'] == near_greentea.id }['distance_meters']
        expect(actual).to be_within(5).of(expected)
      end

      it 'caps each array at 50 results' do
        stub_const('Api::V1::NearbyController::MAX_RESULTS', 2)
        create_list(:greentea, 4, latitude: origin_lat, longitude: origin_lng)

        get '/api/v1/nearby', params: { lat: origin_lat, lng: origin_lng }

        expect(response.parsed_body['greenteas'].size).to eq(2)
      end
    end

    context 'with invalid parameters' do
      it 'returns 400 when lat is non-numeric' do
        get '/api/v1/nearby', params: { lat: 'abc', lng: origin_lng }

        expect(response).to have_http_status(:bad_request)
        expect(response.parsed_body).to eq('error' => 'Bad Request')
      end

      it 'returns 400 when lng is non-numeric' do
        get '/api/v1/nearby', params: { lat: origin_lat, lng: 'xyz' }

        expect(response).to have_http_status(:bad_request)
      end

      it 'returns 400 when lat is missing' do
        get '/api/v1/nearby', params: { lng: origin_lng }

        expect(response).to have_http_status(:bad_request)
      end

      it 'returns 400 when lng is missing' do
        get '/api/v1/nearby', params: { lat: origin_lat }

        expect(response).to have_http_status(:bad_request)
      end

      it 'returns 400 when lat is out of range' do
        get '/api/v1/nearby', params: { lat: 200, lng: origin_lng }

        expect(response).to have_http_status(:bad_request)
      end

      it 'returns 400 when lng is out of range' do
        get '/api/v1/nearby', params: { lat: origin_lat, lng: -200 }

        expect(response).to have_http_status(:bad_request)
      end

      it 'returns 400 when radius is non-numeric' do
        get '/api/v1/nearby', params: { lat: origin_lat, lng: origin_lng, radius: 'foo' }

        expect(response).to have_http_status(:bad_request)
      end

      it 'returns 400 when radius is zero or negative' do
        get '/api/v1/nearby', params: { lat: origin_lat, lng: origin_lng, radius: 0 }

        expect(response).to have_http_status(:bad_request)
      end

      it 'returns 400 when radius exceeds the maximum' do
        get '/api/v1/nearby', params: { lat: origin_lat, lng: origin_lng, radius: 100 }

        expect(response).to have_http_status(:bad_request)
      end
    end

    context 'when no spots are within radius' do
      it 'returns empty arrays' do
        create(:greentea, latitude: 40.0, longitude: 140.0)
        create(:temple, latitude: 40.0, longitude: 140.0)

        get '/api/v1/nearby', params: { lat: origin_lat, lng: origin_lng }

        expect(response).to have_http_status(:ok)
        json = response.parsed_body
        expect(json['greenteas']).to eq([])
        expect(json['temples']).to eq([])
      end
    end
  end
end
