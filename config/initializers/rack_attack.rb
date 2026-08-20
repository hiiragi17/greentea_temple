# frozen_string_literal: true

# 荒らし対策: 口コミ投稿・モデルルート作成 API への連投を制限する。
# rack-attack は Rails::Railtie 経由でミドルウェアへ自動的に組み込まれる。
#
# デフォルトのキャッシュストアは Rails.cache を使う（Rack::Attack::Cache.default_store）。
# test 環境は Rails.cache が :null_store のため増分が保存されず、実質スロットリングされない
# （既存のリクエスト spec が連投しても引っかからない）。スロットリング自体のテストは
# spec/requests/api/v1/rate_limiting_spec.rb で明示的にストアを差し替えて検証する。

# 口コミ投稿: 同一IPから1分間に10件まで
Rack::Attack.throttle('comments/create/ip', limit: 10, period: 1.minute) do |req|
  req.ip if req.post? && %w[/api/v1/greenteacomments /api/v1/templecomments].include?(req.path)
end

# モデルルート作成: Directions API 呼び出しを伴い外部APIコストがかかるため、より厳しく1分間に5件まで
Rack::Attack.throttle('routes/create/ip', limit: 5, period: 1.minute) do |req|
  req.ip if req.post? && req.path == '/api/v1/routes'
end

Rack::Attack.throttled_responder = lambda do |req|
  match_data = req.env['rack.attack.match_data']
  retry_after = match_data[:period] - (match_data[:epoch_time] % match_data[:period])

  headers = { 'Content-Type' => 'application/json', 'Retry-After' => retry_after.to_s }
  [429, headers, [{ error: 'Too Many Requests' }.to_json]]
end

# test 環境ではデフォルト無効化し、既存の spec に影響を与えないようにする。
# スロットリングの挙動自体は spec/requests/api/v1/rate_limiting_spec.rb で
# enabled / cache store を一時的に差し替えて検証する。
Rack::Attack.enabled = false if Rails.env.test?
