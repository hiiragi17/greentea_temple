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
  let(:temple) { create(:temple) }

  # 経路作成は Directions API を呼ぶため、外部 HTTP を避けるために stub する
  # (spec/requests/api/v1/routes_spec.rb と同様)。
  before { allow(DirectionsService).to receive(:leg).and_return(nil) }

  around do |example|
    original_enabled = Rack::Attack.enabled
    original_store = Rack::Attack.cache.store

    Rack::Attack.enabled = true
    Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new

    example.run

    Rack::Attack.enabled = original_enabled
    Rack::Attack.cache.store = original_store
  end

  it 'returns 429 with a JSON error body and Retry-After header once the greentea comment throttle limit is exceeded' do
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
    expect(response.headers['Retry-After']).to be_present
  end

  it 'returns 429 with a JSON error body and Retry-After header once the temple comment throttle limit is exceeded' do
    10.times do
      post '/api/v1/templecomments',
           params: { templecomment: { temple_id: temple.id, body: '連投テスト' } },
           headers: auth
    end
    expect(response).to have_http_status(:ok)

    post '/api/v1/templecomments',
         params: { templecomment: { temple_id: temple.id, body: '11件目の連投' } },
         headers: auth

    expect(response).to have_http_status(:too_many_requests)
    expect(response.media_type).to eq('application/json')
    expect(response.parsed_body['error']).to be_present
    expect(response.headers['Retry-After']).to be_present
  end

  it 'returns 429 with a JSON error body and Retry-After header once the route throttle limit is exceeded' do
    route_params = { route: { name: '連投ルート', spots: [{ spot_type: 'greentea', spot_id: greentea.id }] } }

    5.times { post '/api/v1/routes', params: route_params, headers: auth }
    expect(response).to have_http_status(:created)

    post '/api/v1/routes', params: route_params, headers: auth

    expect(response).to have_http_status(:too_many_requests)
    expect(response.media_type).to eq('application/json')
    expect(response.parsed_body['error']).to be_present
    expect(response.headers['Retry-After']).to be_present
  end

  it 'does not throttle requests to unrelated API paths' do
    11.times { get '/api/v1/health' }

    expect(response).to have_http_status(:ok)
  end

  it 'throttles requests even when a .json format suffix is used to bypass the exact path match' do
    10.times do
      post '/api/v1/greenteacomments.json',
           params: { greenteacomment: { greentea_id: greentea.id, body: '連投テスト' } },
           headers: auth
    end
    expect(response).to have_http_status(:ok)

    post '/api/v1/greenteacomments.json',
         params: { greenteacomment: { greentea_id: greentea.id, body: '11件目の連投' } },
         headers: auth

    expect(response).to have_http_status(:too_many_requests)
  end

  # Cloud Run はコンテナ手前の内部プロキシからリンクローカルアドレス(169.254.0.0/16)で
  # 接続してくる。REMOTE_ADDR がその内部プロキシの共通アドレスになりすべてのユーザーの
  # リクエストが同一に見えてしまうと、一人のユーザーが上限に達しただけで無関係な他ユーザーの
  # ルート作成まで巻き込みでブロックされてしまう。X-Forwarded-For の実クライアントIPで
  # 正しく区別できることを確認する。
  it 'scopes the route throttle per real client IP behind a Cloud Run-style link-local proxy' do
    proxy_env = { 'REMOTE_ADDR' => '169.254.1.1' }
    route_params = { route: { name: '連投ルート', spots: [{ spot_type: 'greentea', spot_id: greentea.id }] } }

    5.times do
      post '/api/v1/routes',
           params: route_params,
           headers: auth.merge('X-Forwarded-For' => '203.0.113.1').merge(proxy_env)
    end
    expect(response).to have_http_status(:created)

    post '/api/v1/routes',
         params: route_params,
         headers: auth.merge('X-Forwarded-For' => '203.0.113.1').merge(proxy_env)
    expect(response).to have_http_status(:too_many_requests)

    # 別クライアント(別 X-Forwarded-For)からのリクエストは巻き込まれず作成できる。
    post '/api/v1/routes',
         params: route_params,
         headers: auth.merge('X-Forwarded-For' => '203.0.113.2').merge(proxy_env)
    expect(response).to have_http_status(:created)
  end
end
