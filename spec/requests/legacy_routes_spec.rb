require 'rails_helper'

# #136 段階1: 旧 Web フロント（抹茶店／神社の閲覧・いいね・口コミ・現在地検索）の
# HTML ルートが 410 Gone を返すことを検証する。
RSpec.describe 'Legacy web routes (#136 段階1)', type: :request do
  describe '410 Gone を返す' do
    {
      'greenteas#index' => '/greenteas',
      'greenteas#show' => '/greenteas/1',
      'greentea_likes 一覧' => '/greenteas/greentea_likes',
      'temples#index' => '/temples',
      'temples#show' => '/temples/1',
      'temple_likes 一覧' => '/temples/temple_likes',
      'current_location#search' => '/current_location',
      'current_location#result' => '/current_location/result'
    }.each do |label, path|
      it "GET #{label} (#{path})" do
        get path
        expect(response).to have_http_status(:gone)
      end
    end

    it 'いいね作成(POST)も 410（CSRF で 422 にならない）' do
      post '/greentea_likes', params: { greentea_id: 1 }
      expect(response).to have_http_status(:gone)
    end

    it '口コミ削除(DELETE)も 410' do
      delete '/greenteacomments/1'
      expect(response).to have_http_status(:gone)
    end

    it 'JSON リクエストにはエラーボディを返す' do
      get '/greenteas', headers: { 'Accept' => 'application/json' }
      expect(response).to have_http_status(:gone)
      expect(response.parsed_body['error']).to eq('gone')
    end
  end

  describe '残存ビューが参照する名前付きルートヘルパーは維持される' do
    it 'greenteas_path / temples_path 等が解決でき 410 を返す' do
      expect { greenteas_path }.not_to raise_error
      expect { temples_path }.not_to raise_error
      expect { greentea_path(1) }.not_to raise_error
      expect { temple_path(1) }.not_to raise_error
      expect { greentea_likes_greenteas_path }.not_to raise_error
      expect { temple_likes_temples_path }.not_to raise_error
      expect { current_location_path }.not_to raise_error
    end
  end
end
