# 抹茶と神社。(greentea_temple)

京都の抹茶スイーツ店と神社仏閣を横断検索できる Web アプリ。
気になった店・神社の近隣スポットを地図上で同時に確認でき、ユーザー登録するといいね / 口コミ / モデルルート作成が利用できる。

サービス URL: https://www.matcha-to-jinja.com/

## 技術スタック

- Ruby 3.3.11（#119 で 3.1.2 から上げ済み）
- Ruby on Rails 7.0.3（→ #124 で 7.1.x へ上げる予定）
- PostgreSQL
- Sorcery（LINE / Google OAuth）
- Ransack（検索）/ Kaminari（ページネーション）
- Geokit + Geocoder（緯度経度・距離計算）
- CarrierWave + MiniMagick（画像アップロード）
- Administrate（管理画面）
- Tailwind CSS + daisyUI（jsbundling-rails / cssbundling-rails）
- RSpec + FactoryBot + Capybara
- デプロイ: GCP Cloud Run + Neon PostgreSQL（#118 で移行予定）
  - ⚠️ **Heroku には今後デプロイしない**（過去運用）

外部 API:
- Google Geocoding API（住所→緯度経度）
- Google Maps JavaScript API（地図描画）
- Google Directions API（モデルルートの経路・所要時間計算。#153）

## セットアップ / よく使うコマンド

```bash
bundle install
yarn install
bin/rails db:setup                # DB 作成 + migrate + seed
bin/dev                           # Procfile.dev で rails + JS/CSS watch を同時起動
bin/rails server -p 3001          # API 開発時はフロント (Next.js: 3000) と分けるため 3001
bundle exec rspec                 # 全テスト
bundle exec rspec spec/requests   # API request spec のみ
bundle exec rubocop
```

## 必須環境変数

| 変数名 | 用途 |
|---|---|
| `GOOGLE_GEOCODING_API_KEY` | 住所 → 緯度経度（Geocoder） |
| `GOOGLE_MAPS_API_KEY` | 地図描画（JS から参照）。`GOOGLE_DIRECTIONS_API_KEY` 未設定時は経路計算でも再利用 |
| `GOOGLE_DIRECTIONS_API_KEY` | モデルルートの経路・所要時間計算（Directions API・#153）。未設定なら `GOOGLE_MAPS_API_KEY` にフォールバック |
| `GOOGLE_CLIENT_ID` / `GOOGLE_CLIENT_SECRET` | Google OAuth（#90 で Twitter から移行） |
| `LINE_KEY` / `LINE_SECRET` | LINE OAuth |
| `DATABASE_URL` | 本番 PostgreSQL（#118 で Neon へ移行予定） |
| `FRONTEND_URL` | CORS allowlist。開発: `http://localhost:3000` / 本番: `https://matcha-to-jinja.com`（#113〜） |
| `JWT_SECRET_KEY` | API 用 JWT 署名（#115〜） |
| `RAILS_MASTER_KEY` | `credentials.yml.enc` 復号 |
| `APP_HOSTS`（任意） | 本番の Host Authorization 追加許可リスト（カンマ区切り）。本番は常時有効で `*.run.app` を自動許可。カスタムドメインは本変数で追加する（未設定でも `*.run.app` のみ許可＝fail-open しない）。`/api/v1/health` は除外（#118） |

## DB 構成

スポット系:
- `greenteas` — 抹茶スイーツ店（name, address, access, business_hours, holiday, latitude, longitude, img 等）
- `temples` — 神社仏閣（同上）
- `genres` — 抹茶店のジャンル / `areas` — 神社の地域
- `greentea_genres` / `temple_areas` — 中間テーブル

ユーザー系:
- `users` — Sorcery core（name, crypted_password 等）
- `authentications` — Sorcery external（provider, uid。LINE / Google）

ソーシャル系:
- `greentea_likes` / `temple_likes` — いいね（`(user_id, *_id)` で UNIQUE）
- `greenteacomments` / `templecomments` — 口コミ

距離検索:
- Greentea / Temple の `latitude` / `longitude` を Geokit で 1.5km 圏内検索

> **テーブル名の注意**: `greenteacomments` / `templecomments` はアンダースコアなしが**実際のテーブル名**（schema.rb のまま）。
> Rails の命名規則 (`greentea_comments` / `temple_comments`) と異なるが、既存データのため変更しない。
> 修正系のマイグレーションを生成しないこと。

ER 図: https://i.gyazo.com/296fbadf44c1309af6a5decb160e745b.png

## ディレクトリ構成

```text
app/
  controllers/
    admin/              # Administrate 管理画面
    api/v1/             # 【新規】Next.js フロント向け API（#113 で着地）
    greenteas_controller.rb, temples_controller.rb
    greentea_likes_controller.rb, temple_likes_controller.rb
    greenteacomments_controller.rb, templecomments_controller.rb
    current_location_controller.rb    # 現在地検索
    oauths_controller.rb              # Sorcery OAuth callback
    user_sessions_controller.rb, users_controller.rb
    static_pages_controller.rb
  models/
    greentea.rb, temple.rb, area.rb, genre.rb
    greentea_genre.rb, temple_area.rb
    greentea_like.rb, temple_like.rb
    greenteacomment.rb, templecomment.rb
    user.rb, authentication.rb
  dashboards/           # Administrate dashboards
  views/                # 既存 Web 画面（HTML / Turbo）
  javascript/           # Stimulus controllers
  assets/stylesheets/   # Tailwind + daisyUI

config/
  routes.rb             # 既存 HTML ルート + api/v1 名前空間
  initializers/cors.rb  # 【新規 #113】

db/
  migrate/, schema.rb, seeds.rb

spec/                   # RSpec
```

## 認証戦略

ハイブリッド構成（Web セッション + API JWT）:

- **既存 Web 画面**: Sorcery のセッション認証（Cookie）でそのまま運用
- **新規 API（#113〜）**: Sorcery の OAuth プロバイダ実装は再利用しつつ、フロント (Next.js) には JWT を発行
  - フロー: NextAuth で OAuth → `access_token` を Rails に渡す → Rails が Sorcery で User を upsert → JWT 返却
  - 詳細: #115

外部認証プロバイダ: LINE / Google（#90 で Twitter を廃止し Google を追加）

JWT ライブラリ: `jwt` gem（HS256 / 有効期限 14 日。詳細は #115）。
署名鍵は `Rails.application.credentials.jwt_secret` または `ENV['JWT_SECRET_KEY']`。

## 進行中の大型タスク: Rails API 化

Next.js フロントエンド (matcha-to-jinja) からの参照用に API を実装する。
依存順:

```text
#119 [Ruby 3.1 → 3.3] ✅ merged
   ↓
#124 [Rails 7.0 → 7.1 アップグレード]   ← API 化の前に着地
   ↓
#113 [API 基盤（api/v1 + CORS + Sorcery 0.18 へ更新）]
   ↓
   ├─ #114 [読み取り系 API]
   ├─ #115 [JWT 認証 API]
   │     ↓
   │     └─ #116 [いいね・コメント API]
   └─ #117 [近隣検索 API]
        ↓
        #118 [GCP Cloud Run + Neon PostgreSQL + GCS]
```

> **#124（Rails アップグレード）を先に着地させる理由**:
> - Sorcery 0.18 が `railties >= 7.1` を要求し、API で使う認証ライブラリが揃わない
> - API コードを 7.0 で書いた後に上げると `ActionController::API` / `ErrorReporter` 周りで再回帰が発生する
> - 詳細は PR #123 のコメント参照

レスポンス契約は matcha-to-jinja 側の `docs/migration-plan.md` の 1-3 を **必ず正**として扱う。
フロントの mock データ (`src/lib/api/mock/data.ts`) と同じスキーマで返す。

### 主要エンドポイント（要約）

```text
GET    /api/v1/health
GET    /api/v1/greenteas              # 一覧。q[name_cont] / q[genres_id_eq] + page
GET    /api/v1/greenteas/:id          # 詳細 + nearby_temples（≤1.5km）
GET    /api/v1/temples                # 一覧
GET    /api/v1/temples/:id            # 詳細 + nearby_greenteas
GET    /api/v1/genres                 # 全件返す（ページネーションなし・meta なし）
GET    /api/v1/areas                  # 全件返す（ページネーションなし・meta なし）
GET    /api/v1/nearby?lat&lng&radius  # 現在地から radius km 以内
POST   /api/v1/auth/:provider         # OAuth → JWT 発行
GET    /api/v1/current_user
GET    /api/v1/greentea_likes         # 認証必須
POST   /api/v1/greentea_likes
DELETE /api/v1/greentea_likes/:id     # :id = greentea_id として解決
(temple_likes / greenteacomments / templecomments も同型)
```

### レスポンス共通フィールド（snake_case）

- スポット系: `id, name, address, access, business_hours, holiday, latitude, longitude, img, likes_count, liked_by_current_user`（`liked_by_current_user` は詳細のみ。一覧は含めない）
- 近隣配列の各要素: `id, name, latitude, longitude, distance_meters`（整数）
- 一覧の `meta`: `{ current_page, total_pages, total_count }`（`per_page` はフロント (matcha-to-jinja) の fixtures が使わないため返さない）

## コーディング規約

### Controller / 認証境界

- 既存の `ApplicationController` は **触らない**（Web 側に影響が出る）
- API は `Api::V1::BaseController < ActionController::API` を別系統で持つ
- API のエラーは JSON で返す: 401 / 403 / 404 / 400 / 422 / 500
- `current_user` の解決は Web 側 = セッション / API 側 = JWT で完全に分離

### Serializer

- API レスポンスは `jsonapi-serializer` を使う（#114 で導入）
- 詳細用の `nearby_*` は専用 serializer に切り出す（距離情報を含むため）
- 一覧の `meta` は `{ current_page, total_pages, total_count }` で統一（`per_page` は返さない＝フロント未使用）

### Ransack

- `ransackable_attributes` / `ransackable_associations` を **必ず allowlist で明示**
- 検索キーは API ドキュメントに記載（`q[name_cont]`, `q[genres_id_eq]`, `q[areas_id_eq]` 等）

### 距離計算

- Geokit の `Geokit::LatLng#distance_to` を使う。**デフォルト単位は km**
- 既存コード (`app/models/temple.rb`, `app/models/greentea.rb`) では km 戻り値に `* 1000` してメートル化している
- API では `distance_meters` を **整数** で返す（`.round` で整数化）
- 例:

  ```ruby
  origin = Geokit::LatLng.new(lat, lng)
  distance_meters = (origin.distance_to(spot) * 1000).round
  # または units を明示する場合
  origin.distance_to(spot, units: :meters).round
  ```

- 一覧クエリで距離付きが必要な場合は N+1 を避ける（`includes` または `select` でまとめて取る）

### テスト

- RSpec の request spec を API の正準テストとする
- 既存 system spec は破壊しない

## 著作権・運用上の注意

- 抹茶店 / 神社の画像は店舗・公式の素材を使う前提。著作権者からの申し立てがあれば即対応
- 口コミは投稿者本人のみ削除可（他人のものは管理者のみ）
- フッターに運営者連絡先・お問い合わせを残す

## GitHub PR ルール

- PR 本文は日本語で書く
- **assignee に `hiiragi17` を必ず設定する**（PR 作成時に忘れず指定）
- 関連 issue がある場合は本文に `Closes #<番号>` を含める
- 1 PR = 1 issue を原則（API 化の親 issue は除く）
- ブランチ命名: `claude/<task-name>` または `feature/<name>` / `fix/<name>`
- **Heroku 固有の検証手順（`heroku stack` / `heroku/ruby` buildpack など）は PR 本文に書かない**。今後のデプロイ先は GCP Cloud Run（#118）のため。

## レビューコメント対応ルール

PR には CodeRabbit / Codex などの bot レビューが付く前提。

### 適用判断

- 小さく明確な指摘（typo / lint / docs / 表記揺れ）→ 即座に修正コミット
- セキュリティ / データ整合性の指摘（SQL injection / N+1 / Ransack の allowlist 漏れ / mass assignment / CORS 設定）→ 妥当性を検証して修正
- アーキテクチャに影響する指摘（責務分離、API 契約変更、認証境界の変更等）→ 自己判断せず AskUserQuestion で確認してから対応
- 複数 bot から同一指摘が来た場合は 1 つの commit でまとめて反映する

### コミットメッセージ

- レビュー反映の commit は `docs: <内容>` や `fix: <内容>` のように内容を要約
- どの指摘を反映したか箇条書きで本文に残す

### 返信ポリシー

- bot / 人間問わず全てのレビューコメントにスレッド返信する (`add_reply_to_pull_request_comment`)
- CodeRabbit の自動 `Addressed in commit XXXXXXX` だけで済ませず、人間が読んでわかる返信を残す
- 返信内容は「対応コミットの hash」+「何をどう変えたかの要約」を必ず含める
- 修正対応した thread は可能なら resolve する (`resolve_review_thread`)
- 「対応しない」判断をした場合は理由を明記してスレッド返信

### スキップしてよいケース

- bot の "Review in progress" の単なる進捗通知
- 既にコミット済みの修正と重複する指摘（返信で既対応を伝えるだけで OK）
- 自分の返信が webhook で echo されてきたケース
- bot の「お礼 / 確認」自動返信（さらに返信すると無限ループになる）

## 関連リポジトリ

- フロントエンド: [hiiragi17/matcha-to-jinja](https://github.com/hiiragi17/matcha-to-jinja)（Next.js / NextAuth.js）
  - 本リポジトリの API 化 issue (#113〜#118) は matcha-to-jinja#13〜#17 / #26 に対応
  - レスポンス契約の正本は `matcha-to-jinja/docs/migration-plan.md`
