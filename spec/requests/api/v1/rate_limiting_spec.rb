require 'rails_helper'

# Rack::Attack はデフォルトで Rails.cache をストアに使う。test 環境の Rails.cache は
# :null_store のため通常は増分が保存されずスロットリングが実質無効になる
# (config/initializers/rack_attack.rb 参照)。ここでは検証のために enabled と
# キャッシュストアを一時的に差し替える。
RSpec.describe 'Rate limiting (Rack::Attack)', type: :request do
  let(:user) { User.create!(name: '連投ユーザー') }
  let(:token) { JwtService.encode({ user_id: user.id }) }
  let(:auth) { { 'Authorization' => "Bearer #{token}" } }
  let(:greentea) { create(:greentea) }

  around do |example|
    original_enabled = Rack::Attack.enabled
    original_store = Rack::Attack.cache.store

    Rack::Attack.enabled = true
    Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new

    example.run

    Rack::Attack.enabled = original_enabled
    Rack::Attack.cache.store = original_store
  end

  it 'returns 429 with a JSON error body once the comment throttle limit is exceeded' do
    10.times do
      post '/api/v1/greenteacomments',
           params: { greenteacomment: { greentea_id: greentea.id, body: '連投テスト' } },
           headers: auth
    end
    expect(response).to have_http_status(:ok)

    post '/api/v1/greenteacomments',
         params: { greenteacomment: { greentea_id: greentea.id, body: '11件目の連投' } },
         headers: auth

    expect(response).to have_http_status(:too_many_requests)
    expect(response.media_type).to eq('application/json')
    expect(response.parsed_body['error']).to be_present
  end

  it 'does not throttle requests to unrelated API paths' do
    11.times { get '/api/v1/health' }

    expect(response).to have_http_status(:ok)
  end
end
