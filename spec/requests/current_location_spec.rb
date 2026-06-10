require 'rails_helper'

RSpec.describe 'CurrentLocation', type: :request do
  describe 'GET /current_location' do
    let!(:greentea) { create(:greentea) }
    let!(:temple) { create(:temple) }

    it 'returns http success' do
      get current_location_path
      expect(response).to have_http_status(:ok)
    end

    it 'renders the map element with the Stimulus controller' do
      get current_location_path
      expect(response.body).to include('data-controller="current-location-map"')
      expect(response.body).to include('id="map"')
    end

    it 'embeds the greentea and temple data for the map' do
      get current_location_path
      expect(response.body).to include('data-current-location-map-greenteas-value=')
      expect(response.body).to include('data-current-location-map-temples-value=')
      expect(response.body).to include(greentea.name)
      expect(response.body).to include(temple.name)
    end
  end

  describe 'GET /current_location/result' do
    it 'returns http success' do
      get '/current_location/result'
      expect(response).to have_http_status(:ok)
    end
  end
end
