# デプロイ手順書（GCP Cloud Run + Neon PostgreSQL）

> 抹茶と神社。(greentea_temple) Rails API を **GCP Cloud Run** にデプロイするための実作業手順書。
> 関連 issue: #118（GCP Cloud Run + Neon PostgreSQL デプロイ）
> コスト・構成の背景は [`deploy-cost-comparison.md`](./deploy-cost-comparison.md) を参照。
> 最終更新: 2026-06-16

## 0. 前提と現状

- デプロイ定義はコード側に**すでに揃っている**:
  - `Dockerfile`（multi-stage / assets precompile / bootsnap / 非 root 起動）
  - `.dockerignore`
  - `.github/workflows/ci.yml`（RuboCop / RSpec / system spec）
  - `.github/workflows/deploy-cloud-run.yml`（Build → Artifact Registry → Cloud Run deploy）
- `deploy-cloud-run.yml` は現状 **手動トリガ（`workflow_dispatch`）のみ**。
  GCP 側のセットアップと各 secrets / vars が揃ったら `main` push 自動デプロイに切り替える。
- 構成図:

  ```text
  [ユーザー] → Vercel(Next.js) → Cloud Run(Rails API) → Neon(PostgreSQL)
                                         └→ GCS(画像配信 ※未実装・将来対応)
  ```

- リージョンは `asia-northeast1`（東京）、サービス名 `greentea-temple`。
- **未実装の注意**: 画像の GCS 配信は**まだコード未対応**（`fog-google` 未導入）。
  初回デプロイは GCS 抜きで進め、GCS 化は別タスクとする（本書「7. 将来対応」）。

---

## ⚠️ デプロイ前チェックリスト（要注意点）

本番反映（特に**本番 DB を作り直す**場合）で踏みやすい落とし穴。上から順に確認する。

### A. データ投入（新規 DB を作り直すケース）

- Cloud Run は**リリース時に `db:migrate` / `db:seed` を自動実行しない**（本書「8. トラブルシュート」）。
  新規 DB は次のいずれかを**手動 or Cloud Run Job** で流す:
  - スキーマ: `bin/rails db:schema:load`（`schema.rb` から一括作成。version は最新 migration と一致済み）
    ／または未適用 migration を `bin/rails db:migrate`
  - 初期データ: `bin/rails db:seed`
- **`db/seeds.rb` が投入する対象**（2026-07 更新）:
  - `genres`（`db/csv/genre.csv`・全18件）
  - `greenteas` + `greentea_genres`（`db/csv/greentea_info.csv`・74件。genre 列は半角スペース区切り）
  - `areas`（`db/csv/area.csv`）
  - `temples` + `temple_areas`（`db/csv/temple_info.csv`・460件）
  - ※以前は greentea / genre がコメントアウトされ**店・ジャンルが入らなかった**。作り直し前提で有効化済み。
- seed は `find_or_create_by! / find_or_initialize_by` ベースで**冪等**（再実行しても重複しない）。
- 本番 DB へ流す場所の選択肢:
  - ローカルから Neon に向けて `DATABASE_URL=<neon-pooled-url> RAILS_ENV=production bin/rails db:seed`
  - もしくは Cloud Run Job で同コマンドを実行
- **既存データを引き継ぐ場合はそもそも seed 不要**。`pg_dump` / `pg_restore`（本書「3-4」）が正。

### B. ジオコーディング API が seed 実行時に走る（重要・課金注意）

- `Greentea` / `Temple` は保存時に住所ジオコーディングする（`after_validation :geocode`）。
  そのため **seed 1 行につき Google Geocoding API を 1 回**呼ぶ（合計 **≈534 リクエスト**: greentea 74 + temple 460）。
- 事前確認:
  - [ ] `GOOGLE_GEOCODING_API_KEY` を seed 実行環境に設定（未設定だと緯度経度が入らず**距離検索 API が壊れる**）
  - [ ] 当該キーの API クォータ / 課金上限を確認（無料枠を超えると 429 / 課金）
  - [ ] 大量リクエストでレート制限に当たる場合は分割実行、または投入後に緯度経度 NULL の行がないか検証
    （`Greentea.where(latitude: nil).count` / `Temple.where(latitude: nil).count` が 0 であること）
- ローカルで一度流し、**店データと緯度経度が期待どおり入るか**を本番前に必ずリハーサルする。

### C. その他の既知の齟齬

- **LINE ログインは ENV では有効化されない** → `credentials.yml.enc` に `line.channel_id` /
  `line.channel_secret` が必要（本書「4」の⚠️を参照）。
- `FRONTEND_URL` を本番値（`https://matcha-to-jinja.com`）にしないと CORS で弾かれる。
- `DATABASE_URL` は Neon の **pooler 経由 + `sslmode=require`**。
- `/api/v1/health` は **DB 非接続**なので 200 でも DB 疎通の証明にならない。
  デプロイ後は `/api/v1/greenteas` など**実データを返すエンドポイント**も叩いて DB 接続まで確認する。

---

## 1. 必要なもの（事前準備）

- GCP アカウントと課金有効なプロジェクト（無料枠内運用想定）
- `gcloud` CLI（ローカル or Cloud Shell）
- Neon アカウント（東京リージョン）
- このリポジトリの GitHub 管理者権限（Secrets / Variables 設定のため）
- 既存 DB のデータ（移行する場合のバックアップ）

以下、シェル変数を使い回す:

```bash
export PROJECT_ID=<your-gcp-project-id>
export REGION=asia-northeast1
export REPO=greentea-temple          # Artifact Registry リポジトリ名（= GitHub vars.AR_REPOSITORY）
export SERVICE=greentea-temple        # Cloud Run サービス名（workflow の SERVICE_NAME と一致）
```

---

## 2. GCP 一回限りのセットアップ

### 2-1. プロジェクト設定 & API 有効化

```bash
gcloud config set project "$PROJECT_ID"
gcloud services enable \
  run.googleapis.com \
  artifactregistry.googleapis.com \
  iamcredentials.googleapis.com \
  sts.googleapis.com
```

### 2-2. Artifact Registry（Docker イメージ置き場）

```bash
gcloud artifacts repositories create "$REPO" \
  --repository-format=docker \
  --location="$REGION" \
  --description="greentea_temple container images"
```

> イメージの肥大を防ぐため、安定後に lifecycle policy で世代を絞ること（本書「6. 運用」）。

### 2-3. デプロイ用サービスアカウント

```bash
gcloud iam service-accounts create gh-deployer \
  --display-name="GitHub Actions deployer"

export SA="gh-deployer@${PROJECT_ID}.iam.gserviceaccount.com"

for role in \
  roles/run.admin \
  roles/artifactregistry.writer \
  roles/iam.serviceAccountUser; do
  gcloud projects add-iam-policy-binding "$PROJECT_ID" \
    --member="serviceAccount:${SA}" \
    --role="$role"
done
```

> Cloud Run のランタイム SA（デフォルトは Compute Engine default SA）にも、
> Neon は外部接続なので追加権限は不要。GCS 化する場合のみ後で storage 権限を付与する。

### 2-4. Workload Identity Federation（鍵レス認証）

GitHub Actions が JSON 鍵なしで GCP に認証するための設定。

```bash
export PROJECT_NUMBER=$(gcloud projects describe "$PROJECT_ID" --format='value(projectNumber)')

# Pool
gcloud iam workload-identity-pools create github \
  --location=global \
  --display-name="GitHub Actions Pool"

# Provider（このリポジトリからのトークンのみ受け付ける）
gcloud iam workload-identity-pools providers create-oidc github-actions \
  --location=global \
  --workload-identity-pool=github \
  --display-name="GitHub Actions Provider" \
  --issuer-uri="https://token.actions.githubusercontent.com" \
  --attribute-mapping="google.subject=assertion.sub,attribute.repository=assertion.repository" \
  --attribute-condition="assertion.repository=='hiiragi17/greentea_temple'"

# このリポジトリの実行だけが SA を借りられるよう紐付け
gcloud iam service-accounts add-iam-policy-binding "$SA" \
  --role=roles/iam.workloadIdentityUser \
  --member="principalSet://iam.googleapis.com/projects/${PROJECT_NUMBER}/locations/global/workloadIdentityPools/github/attribute.repository/hiiragi17/greentea_temple"
```

GitHub Secrets に登録する **provider のリソース名** を控える:

```bash
echo "projects/${PROJECT_NUMBER}/locations/global/workloadIdentityPools/github/providers/github-actions"
# → これを secret GCP_WORKLOAD_IDENTITY_PROVIDER に設定
echo "$SA"
# → これを secret GCP_DEPLOY_SERVICE_ACCOUNT に設定
```

---

## 3. Neon PostgreSQL セットアップ

1. Neon でプロジェクトを **東京リージョン**で作成。
2. 開発用 / 本番用にブランチを分ける。
3. **Pooled connection** の接続文字列を取得し、SSL を必須にする:
   - 例: `postgres://<user>:<pass>@<host>-pooler.<region>.aws.neon.tech/<db>?sslmode=require`
   - Cloud Run の同時実行で接続が枯渇しないよう **pooler 経由**を使う。
4. 既存 DB からの移行（必要な場合）:

   ```bash
   # 旧 DB をダンプ
   pg_dump --no-owner --no-privileges -Fc "$OLD_DATABASE_URL" -f dump.pgsql
   # Neon へリストア
   pg_restore --no-owner --no-privileges -d "$NEON_DATABASE_URL" dump.pgsql
   ```

5. この接続文字列を GitHub Secret `DATABASE_URL` に設定する。

> ⚠️ 新規 DB の場合はスキーマ適用が必要。`bin/rails db:schema:load` を流すか、
> 初回起動前に migration を当てる運用を決めておく（Cloud Run はリリース時に migration を
> 自動実行しないため、必要なら別途 Cloud Run Job / 手動で `db:migrate` を実行する）。

---

## 4. GitHub Secrets / Variables 登録

リポジトリ → **Settings → Secrets and variables → Actions**。
（`deploy-cloud-run.yml` が参照しているキーと完全一致させること）

### Secrets

| キー | 値 | 取得元 |
|---|---|---|
| `GCP_PROJECT_ID` | GCP プロジェクト ID | `$PROJECT_ID` |
| `GCP_WORKLOAD_IDENTITY_PROVIDER` | WIF provider リソース名 | 2-4 の出力 |
| `GCP_DEPLOY_SERVICE_ACCOUNT` | デプロイ SA のメール | `$SA` |
| `DATABASE_URL` | Neon の pooled 接続文字列（`sslmode=require`） | 3 |
| `RAILS_MASTER_KEY` | `config/master.key` の値 | ローカル |
| `JWT_SECRET_KEY` | API 用 JWT 署名鍵 | 任意の十分長い乱数 |
| `GMAP_API` | Geocoding 用 API キー | Google Cloud Console |
| `GOOGLE_MAP_API` | Maps JS API キー | Google Cloud Console |
| `LINE_KEY` | LINE OAuth キー（※下記注意） | LINE Developers |
| `LINE_SECRET` | LINE OAuth シークレット（※下記注意） | LINE Developers |
| `SECRET_KEY_BASE` | （任意）未設定なら credentials 由来を使用 | 任意 |

> `SECRET_KEY_BASE` は **secret が存在するときのみ** Cloud Run に渡される実装。
> credentials.yml.enc 側に持たせるなら未設定で OK（`RAILS_MASTER_KEY` で復号される）。

> ⚠️ **LINE OAuth の認証情報は環境変数では読まれない**（重要）
> `config/initializers/sorcery.rb` は LINE の key/secret を **encrypted credentials** から読む:
>
> ```ruby
> config.line.key    = Rails.application.credentials.dig(:line, :channel_id)
> config.line.secret = Rails.application.credentials.dig(:line, :channel_secret)
> ```
>
> そのため上表の `LINE_KEY` / `LINE_SECRET` を Cloud Run に渡しても **Sorcery は参照せず、LINE
> ログインは有効化されない**（`deploy-cloud-run.yml` がこれらを env で渡しているのは現状
> アプリ側と未整合）。LINE ログインを本番で動かすには、**`credentials.yml.enc` に
> `line.channel_id` / `line.channel_secret` を設定**し（`RAILS_MASTER_KEY` で復号）、
> その値を使うこと。GitHub Secrets の `LINE_KEY` / `LINE_SECRET` は現状不要。
>
> （根本対応として initializer を `ENV['LINE_KEY']` 参照へ寄せる選択肢もあるが、認証境界に
> 触れるため本手順書のスコープ外。別 issue で扱う。）

### Variables

| キー | 値 |
|---|---|
| `AR_REPOSITORY` | Artifact Registry リポジトリ名（`$REPO`） |
| `FRONTEND_URL` | CORS allowlist（本番: `https://matcha-to-jinja.com`） |
| `APP_HOSTS` | （任意）追加許可ホスト（カンマ区切り）。`*.run.app` は本番で自動許可 |

---

## 5. 初回デプロイ

1. GitHub → **Actions** → **Deploy to Cloud Run** → **Run workflow**。
   - `image_tag` は空でよい（commit SHA の先頭 12 桁が使われる）。
2. ジョブの流れ:
   - WIF で GCP 認証 → `docker build` → Artifact Registry push → `deploy-cloudrun` で Cloud Run へ。
   - デプロイ flags: `--allow-unauthenticated --memory=512Mi --cpu=1 --min-instances=0 --max-instances=4`。
3. 最終ステップでサービス URL が出力される。

### 受け入れ確認（#118 の受け入れ条件）

```bash
curl -i https://<cloud-run-url>/api/v1/health   # → 200 / {"status":"ok"}
```

- [ ] `/api/v1/health` が 200
- [ ] フロント（Vercel preview）から CORS エラーなく API を叩ける
- [ ] スケールトゥゼロから初回レスポンスが返る（コールドスタート許容）

### カスタムドメイン

`api.matcha-to-jinja.com` を Cloud Run にマッピング:

```bash
gcloud run domain-mappings create \
  --service="$SERVICE" \
  --domain=api.matcha-to-jinja.com \
  --region="$REGION"
```

表示される DNS レコードをドメイン側に設定。SSL は自動発行。

---

## 6. 確認後の仕上げ（自動化・運用）

1. **自動デプロイ化**: `deploy-cloud-run.yml` の `on:` に以下を追加。

   ```yaml
   on:
     push:
       branches: [main]
     workflow_dispatch:
       inputs:
         image_tag: { ... }   # 既存のまま
   ```

2. ~~**Actions の SHA ピン**~~: 対応済み。`auth` / `setup-gcloud` / `deploy-cloudrun`
   は `v3` タグの commit SHA に固定済み（`# v3` コメントで版を併記）。
3. **Artifact Registry の lifecycle policy**: 古い tag を自動削除し 0.5GB 無料枠を維持。
4. **コールドスタート対策（任意）**: Cloud Scheduler で `/api/v1/health` を定期的に叩いて
   Cloud Run をウォーム維持（`/api/v1/health` は DB 非接続なので Neon は温まらない点に注意）。
   詳細は [`deploy-cost-comparison.md`](./deploy-cost-comparison.md) の「4. 弱点克服 Tips」。

---

## 7. 将来対応（GCS 画像配信・未実装）

現状 `fog-google` 未導入のため、画像の GCS 配信は**コード対応が別途必要**。実装時のタスク:

- [ ] `fog-google` gem 追加
- [ ] CarrierWave を `production` 環境のみ `:fog`（GCS）へ切替
- [ ] GCS バケット作成（`asia-northeast1` / 公開読み取り）
- [ ] Cloud Run ランタイム SA に storage 権限付与
- [ ] `deploy-cloud-run.yml` の env_vars に `GCP_PROJECT_ID` / `GCS_BUCKET` 等を追加
- [ ] 既存画像の GCS への移行

---

## 8. トラブルシュート

| 症状 | 確認ポイント |
|---|---|
| 認証エラー（`auth` step で失敗） | WIF の `attribute-condition` のリポジトリ名、SA の `workloadIdentityUser` 紐付け、3 つの GCP secret |
| `docker push` で権限エラー | SA の `roles/artifactregistry.writer`、`AR_REPOSITORY` 変数とリポジトリ名の一致 |
| 起動後 500 / DB 接続不可 | `DATABASE_URL` の `sslmode=require`、pooler ホスト、Neon オートサスペンドからの復帰 |
| Host Authorization で弾かれる | `APP_HOSTS` にカスタムドメインを追加（`*.run.app` は本番自動許可） |
| アセットが出ない | Dockerfile の `assets:precompile` 成否、`RAILS_SERVE_STATIC_FILES=1`（runtime で設定済み） |
| migration 未反映 | Cloud Run は自動で `db:migrate` しない。Cloud Run Job か手動で実行する |
