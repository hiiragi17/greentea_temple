require 'rails_helper'

# PWA: Rails 8 標準の Rails::PwaController が app/views/pwa/* を配信することを検証する
RSpec.describe 'PWA', type: :request do
  describe 'GET /manifest.json' do
    it 'Web App Manifest を JSON で返す' do
      get '/manifest.json'
      expect(response).to have_http_status(:ok)

      json = JSON.parse(response.body)
      expect(json['name']).to eq('抹茶と神社。')
      expect(json['start_url']).to eq('/')
      expect(json['display']).to eq('standalone')
      expect(json['icons']).to be_an(Array)
      expect(json['icons']).not_to be_empty
    end
  end

  describe 'GET /service-worker.js' do
    it 'Service Worker スクリプトを JavaScript で返す' do
      get '/service-worker.js'
      expect(response).to have_http_status(:ok)
      expect(response.media_type).to eq('text/javascript')
      expect(response.body).to include('addEventListener')
    end
  end
end
