# frozen_string_literal: true

# 荒らし対策: 口コミ投稿・モデルルート作成 API への連投を制限する。
# rack-attack は Rails::Railtie 経由でミドルウェアへ自動的に組み込まれる。
#
# デフォルトのキャッシュストアは Rails.cache を使う（Rack::Attack::Cache.default_store）。
# test 環境は Rails.cache が :null_store のため増分が保存されず、実質スロットリングされない
# （既存のリクエスト spec が連投しても引っかからない）。スロットリング自体のテストは
# spec/requests/api/v1/rate_limiting_spec.rb で明示的にストアを差し替えて検証する。

# Rack::Attack::Request は素の Rack::Request のサブクラスで、req.ip は Rack 自身が
# 持つ trusted proxy 判定（rack gem 内蔵の固定リスト）で計算される。このリストには
# リンクローカルアドレス(169.254.0.0/16 等)が含まれていない。
# 一方 Cloud Run はコンテナの手前の内部プロキシからリンクローカルアドレスで接続してくるため、
# Rails 側の ActionDispatch::RemoteIp（config.action_dispatch.trusted_proxies。デフォルトで
# 169.254.0.0/16 を含む）は X-Forwarded-For から正しい実クライアントIPを解決できるのに対し、
# req.ip はそれを信頼できず REMOTE_ADDR（＝内部プロキシの同一アドレス）を返してしまう。
# 結果、本番では全リクエストが同一IP扱いになり、スロットルが特定ユーザーではなく
# サイト全体で共有されてしまう（誰か一人が上限に達すると全員がルート/口コミを作成できなくなる）。
# ActionDispatch::RemoteIp ミドルウェアは Rack::Attack より先にミドルウェアスタックを通るため、
# 計算済みの env['action_dispatch.remote_ip'] を優先して使い、無ければ req.ip にフォールバックする。
CLIENT_IP = lambda do |req|
  req.env['action_dispatch.remote_ip']&.to_s || req.ip
end

# 口コミ投稿: 同一IPから1分間に10件まで
# `resources` はデフォルトで (.:format) を許容するため、パスの完全一致ではなく
# 末尾の .json 等のフォーマット拡張子を許容する正規表現でマッチさせる
# （完全一致だと /api/v1/greenteacomments.json 等でスロットルを回避できてしまう）
Rack::Attack.throttle('comments/create/ip', limit: 10, period: 1.minute) do |req|
  CLIENT_IP.call(req) if req.post? && req.path.match?(%r{\A/api/v1/(?:greenteacomments|templecomments)(?:\.\w+)?\z})
end

# モデルルート作成: Directions API 呼び出しを伴い外部APIコストがかかるため、より厳しく1分間に5件まで
Rack::Attack.throttle('routes/create/ip', limit: 5, period: 1.minute) do |req|
  CLIENT_IP.call(req) if req.post? && req.path.match?(%r{\A/api/v1/routes(?:\.\w+)?\z})
end

# OAuthログイン: 未認証で誰でも叩ける唯一のPOSTエンドポイントであり、
# リクエスト毎にLINE/GoogleへのサーバーS2Sリクエスト(タイムアウト5秒)が発生するため、
# 連打によるPumaスレッド枯渇・外部APIへの負荷を防ぐ目的で1分間に5件までに制限する
Rack::Attack.throttle('auth/create/ip', limit: 5, period: 1.minute) do |req|
  CLIENT_IP.call(req) if req.post? && req.path.match?(%r{\A/api/v1/auth/[^/]+(?:\.\w+)?\z})
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
