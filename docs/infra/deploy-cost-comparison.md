# デプロイ構成のコスト比較資料

> 抹茶と神社。(greentea_temple) を **できるだけ安く運用する** ための構成比較メモ。
> 関連 issue: #118（GCP Cloud Run + Neon PostgreSQL デプロイ）
> 最終更新: 2026-06-05

## 0. 前提

- アプリは **Rails 7.1 / Ruby 3.3** の API + 管理画面 + 既存 Web 画面。
- フロントは別リポジトリ（[matcha-to-jinja](https://github.com/hiiragi17/matcha-to-jinja) / Next.js）で **Vercel Hobby（無料）** 想定。
- 画像は **CarrierWave**（Active Storage ではない）。本番のみ外部ストレージへ。
- **個人サービス規模 = 低トラフィック** を前提にコストを試算（同時アクセスはごく少数、画像も数 GB 程度）。
- Heroku には今後デプロイしない（過去運用）。

### 優先軸（本プロジェクトの方針）

**「無料 ＋ ポートフォリオ価値」を最優先**。
→ 金額がほぼ同じなら、実務で評価される技術スタック（GCP / CI-CD / IaC）を選ぶ。

## 1. 比較サマリ

| 構成 | 月額目安（低トラフィック） | コールドスタート | 運用の手間 | ポートフォリオ価値 | 本プロジェクトとの相性 |
|---|---|---|---|---|---|
| **#118: Cloud Run + Neon + GCS** | **~¥0 〜 数百円** | あり（弱点・要対策） | 中（CI/IaC を整えれば後はラク） | **高**（GCP / Cloud Run / WIF / Actions） | ◎ **採用** |
| Oracle Cloud Always Free（1 VM 全部入り） | **¥0**（恒久無料・上限内） | **なし** | 高（自前で全管理） | 中 | ○（金額最強だが見栄え弱め） |
| Fly.io（Rails + Postgres 同居） | ~¥0 〜 $5 | ほぼなし | 中 | 中 | ○ |
| Render | Web 無料はスピンダウン有 / PG は有料（$6〜） | あり | 低 | 低 | △ |
| Railway | $5/月の Hobby サブスク（$5 分のクレジット込み。使用量が $5 以内なら従量課金は発生しないが、**$5/月のサブスク料金自体は発生**） | ほぼなし | 低 | 中 | ○ |

> 💡 **料金・無料枠の数値について（as-of 2026-06-05）**
> 各社の料金・無料枠は頻繁に改定されます。本表の数値は下記「5. 参考」の公式ページを **2026-06-05 時点**で参照したもので、**実際に採用する前に必ず最新の公式ページを確認**してください。特に以下は公式の単価テーブルを都度確認すること:
> - **Cloud Run**: 無料枠は月次でリセットされる "spending-based discount"。上限値（vCPU 秒 / GiB 秒 / リクエスト）は参照する表・リージョンで変わる。
> - **GCS（asia-northeast1 の egress）** / **Fly.io（shared-cpu-1x）**: 本資料では当該リージョン/プランの正確な単価行を確定できていないため、**金額は概算**として扱い、公式ページで確認する。

**結論**: 本プロジェクトの優先軸（無料＋ポートフォリオ価値）では **#118 の Cloud Run + Neon + GCS が最適**。
純粋な「絶対額の最安・コールドスタート無し」だけを取るなら Oracle Cloud 1 台構成が上だが、見栄え・運用手間で本プロジェクトの軸には合わない。

## 2. 各構成の詳細

### 2-1. #118: GCP Cloud Run + Neon + GCS 【採用】

```text
[ユーザー] → Vercel(Next.js) → Cloud Run(Rails API) → Neon(PostgreSQL)
                                       └→ GCS(画像配信)
```

| 項目 | 設定 | コスト | 備考 |
|---|---|---|---|
| Cloud Run | 512Mi / CPU1 / min-instance 0 | ほぼ ¥0 | 無料枠: 200 万 req / 36 万 GB 秒 / 18 万 vCPU 秒（毎月） |
| Neon | 無料プラン | ¥0 | 0.5GB 上限・オートサスペンド |
| GCS | Standard / asia-northeast1 | 数 GB で月 数円〜数十円 | egress（画像配信）が asia は無料枠外 |
| Artifact Registry | Docker イメージ置き場 | 0.5GB 超で $0.10/GB/月 | 古い tag を溜めない |
| Cloud Run egress | — | 小さければ無料枠内 | 無料 egress は **北米リージョンのみ**、asia-northeast1 は対象外 |

**メリット**
- 低トラフィックなら **月額ほぼ ¥0**。
- スケールトゥゼロでアイドル時課金なし。
- WIF（Workload Identity Federation）+ GitHub Actions で **鍵レス自動デプロイ** → 実務評価が高い。
- マネージドで OS/ミドルのお守りが不要。

**デメリット（弱点）**
- **コールドスタート**: Rails 起動は実測 3〜8 秒になりがちで、受け入れ条件「5 秒以内」が際どい。
- Neon 無料枠の **0.5GB 上限・オートサスペンド**。
- GCS egress が asia は有料（人気が出ると効いてくる）。

→ 弱点の具体的な対策は本書「4. #118 弱点克服 Tips」を参照。

### 2-2. Oracle Cloud Always Free（1 VM 全部入り）

```text
[ユーザー] → Caddy(自動SSL) → Rails(Puma)
                                 ├→ PostgreSQL(同一VM)
                                 └→ 画像(ローカル/ブロックストレージ)
```

- **ARM Ampere A1: 4 vCPU / 24GB RAM / 200GB ブロックストレージ / egress 10TB/月** を **恒久無料**。
- Rails + Postgres + 画像 + Caddy を 1 台に同居 → **本当に ¥0・コールドスタート無し（常時起動）**。

**メリット**: 金額最強（¥0）、コールドスタート無し、リソース潤沢。
**デメリット**:
- 全部自前運用（OS パッチ / バックアップ / 監視 / SSL 更新）。
- Oracle が **空きインスタンスを稀に回収** することがある（要・課金アカウント化や常時稼働で緩和）。
- ARM の **Always Free 枠が取りにくい時間帯** がある。
- 単一障害点（1 台に全部）。
- マネージド系の経験としてはアピール度がやや低い。

### 2-3. Fly.io（Rails + Postgres 同居）

- 小型 VM（shared-cpu-1x / 256〜512MB）+ Volume で Postgres。
- 旧来の寛大な無料枠は縮小済み。**実質 ~$0〜$5/月**。
- 永続インスタンスなので **コールドスタート（実質）なし**、`fly deploy` が手軽。
- DB を Fly Postgres（自己管理）にするか外部 Neon にするかは選択可。

### 2-4. Render

- Web Service 無料枠は **非アクティブでスピンダウン**（= コールドスタート有り）。
- 無料 PostgreSQL は提供条件が縮小し、実質 **有料（$6〜/月）**。
- セットアップは簡単だが、無料運用は維持しづらく本プロジェクトの優先軸では不利。

### 2-5. Railway

- 使用量課金。Hobby は **$5/月クレジット** 付き → 小規模なら実質無料に収まることも。
- デプロイは手軽、コールドスタートはほぼなし。
- 無料枠を超えた瞬間に課金が始まる点に注意。

## 3. 推奨

| ゴール | 推奨構成 |
|---|---|
| 無料 ＋ ポートフォリオ価値（**本プロジェクトの方針**） | **#118: Cloud Run + Neon + GCS** |
| とにかく 1 円でも安く・常時きびきび | Oracle Cloud Always Free（1 VM 全部入り） |
| 手軽さと永続稼働のバランス | Fly.io |

## 4. #118 弱点克服 Tips

無料枠（月額ほぼ ¥0）を維持したまま、Cloud Run 構成の弱点を潰すための実装メモ。

### 4-1. コールドスタート（最大の弱点）

- **¥0 を守るなら**: `min-instance=0` のまま、**Cloud Scheduler で数分おきにヘルスチェックを叩いてウォーム維持**（ヘルスチェックは無料枠内に収まる）。受け入れ条件「5 秒以内」の達成しやすさを上げる（あくまで緩和策で、SLO を保証するものではない）。
  - ⚠️ ただし現状の `/api/v1/health`（`app/controllers/api/v1/health_controller.rb`）は `{ status: 'ok' }` を返すだけで **DB に接続しない**。これを叩いても **温まるのは Cloud Run / Rails だけで、Neon は温まらない**（Neon は別途オートサスペンドするため）。`/api/v1/health` は **「Cloud Run のコールドスタート対策のみ・DB 非接続」** と位置づけ、公開のまま使ってよい。
  - Neon も含めて温めたいなら、**軽い DB アクセスを伴うウォームアップ用エンドポイント**（例: `SELECT 1` 相当のクエリを1回投げる）を用意してそれを叩く。ただしこの経路は **公開のままだと意図しない連打で DB 復帰・課金・負荷を誘発**するため、以下で **Cloud Scheduler など内部呼び出しのみに限定**する:
    - **認証**: Cloud Scheduler → Cloud Run は **OIDC トークン**（サービスアカウントの ID トークン）で呼ぶのが基本。アプリ側で受け取った `Authorization: Bearer <token>` の検証、もしくは簡易には **共有シークレットヘッダ**（例: `X-Warmup-Token` を `ENV` の値と比較し、一致しなければ `401`）でガードする。
    - **ネットワーク/Ingress**: 可能なら Cloud Run の **Ingress を internal/allowlist** に寄せる、または warmup 用パスだけ前段（LB / IAM invoker）で絞る。
    - 例（共有シークレット方式の最小チェック）:
      ```ruby
      # warmup#show
      head :unauthorized and return unless
        ActiveSupport::SecurityUtils.secure_compare(
          request.headers['X-Warmup-Token'].to_s, ENV['WARMUP_TOKEN'].to_s
        )
      ActiveRecord::Base.connection.execute('SELECT 1')
      head :ok
      ```
- **確実に消したいなら**: `min-instance=1`（常時 1 台起動）。ただし常時課金で **月 ¥800 前後**になるため、¥0 方針とはトレードオフ。
- 起動高速化: `bootsnap` 有効化（導入済み）、本番 assets は **ビルド時に precompile**（実行時に走らせない）、不要 initializer の見直し。
- `config/puma.rb` の `WEB_CONCURRENCY` / スレッド数を Cloud Run の CPU1 / 512Mi に合わせて控えめに。

### 4-2. Neon 無料枠（0.5GB 上限・オートサスペンド）

- **画像を DB に入れない**（元方針どおり GCS へ）。DB は構造化データのみで当面 0.5GB に十分収まる。
- 接続は **Pooled connection + SSL 必須**（`DATABASE_URL` に `?sslmode=require` 等）。Cloud Run の同時実行で接続枯渇しないよう pooler 経由にする。
- オートサスペンドからの復帰遅延は、**DB アクセスを伴うウォームアップ**（4-1 参照。`/api/v1/health` は DB に触れないため Neon は温まらない点に注意）と合わせれば体感を抑えられる。
- 容量が逼迫してきたら有料化（$19〜）より先に「画像・大きいテキストを外部化できていないか」を見直す。

### 4-3. GCS egress（asia は無料枠外）

- まずは **GCS 直配信 + 適切な `Cache-Control`**（画像は長期キャッシュ可）。
- egress が気になり出したら、画像ドメインに **Cloudflare（無料）を被せてキャッシュ** → オリジン（GCS）への egress が激減する。
- Cloud CDN は最初は不要（最小構成を優先）。

### 4-4. Artifact Registry（イメージ置き場の肥大）

- 古いイメージ tag を溜めると 0.5GB 無料枠を超えて課金。
- **lifecycle policy で世代を絞る**（例: 最新 N 個のみ保持）。
- マルチステージ Docker で最終イメージを小さく保つ（ビルド成果物のみ COPY）。

### 4-5. その他

- `--allow-unauthenticated` で公開しつつ、認証は **アプリ層（JWT / Sorcery セッション）** で担保。
- 環境変数（`RAILS_MASTER_KEY` / `JWT_SECRET_KEY` / `DATABASE_URL` 等）は Cloud Run のシークレット or Secret Manager 経由で注入し、イメージに焼き込まない。
- CI で `bundle exec rspec` / `rubocop` をゲートにし、`main` push → build → Artifact Registry → Cloud Run deploy を WIF で鍵レス自動化。

## 5. 参考

### 料金・無料枠の公式出典（いずれも as-of 2026-06-05 / 採用前に最新を確認）

- **Cloud Run**: 料金 / 無料枠 — https://cloud.google.com/run/pricing
- **Neon**: プラン — https://neon.com/docs/introduction/plans / 無料枠 FAQ — https://neon.com/faqs/managed-postgres-databases-free-tier
- **GCS**: 料金 — https://cloud.google.com/storage/pricing （asia-northeast1 の egress 単価は要確認）
- **Oracle Cloud Always Free**: 無料リソース上限 — https://docs.oracle.com/en-us/iaas/Content/FreeTier/freetier_topic-Always_Free_Resources.htm
- **Fly.io**: 料金 — https://fly.io/docs/about/pricing/ （shared-cpu-1x の単価は要確認）
- **Render**: 料金 — https://render.com/pricing / Postgres — https://render.com/docs/postgresql-refresh
- **Railway**: プラン — https://docs.railway.com/pricing/plans / FAQ — https://docs.railway.com/pricing/faqs

### その他

- matcha-to-jinja（別リポジトリ）の [`docs/migration-plan.md`](https://github.com/hiiragi17/matcha-to-jinja/blob/main/docs/migration-plan.md)（「環境構成」「GCP Cloud Run デプロイ手順」「Neon PostgreSQL セットアップ」）。**本リポジトリには存在しない**（参照先はフロントエンドのリポジトリ）
- 関連 issue: #113 〜 #118（API 化 → デプロイ）

---

## 付録: Vercel の Dockerfile 対応の検討（as-of 2026-07-01）

> 背景: Vercel が「任意の Dockerfile を動かせる」機能を発表したのを受け、**Rails 本体も含めて全部 Vercel に寄せられないか / GCP より安くならないか** を検討した記録。
> 出典: [Run any Dockerfile on Vercel](https://vercel.com/blog/dockerfile-on-vercel) / [Fluid compute pricing](https://vercel.com/docs/functions/usage-and-pricing) / [Active CPU pricing](https://vercel.com/blog/introducing-active-cpu-pricing-for-fluid-compute)

### 何ができるようになったか

- リポジトリに `Dockerfile.vercel` を置くと、Vercel がイメージをビルド・保存・デプロイし、**Fluid compute 上でオートスケール**する。
- **Rails は公式にサポート対象**（Rails / Laravel / Spring Boot / Express / FastAPI / nginx など）。唯一のルールは **サーバが `$PORT`（デフォルト 80）で listen** すること。
- 既存 `Dockerfile` は `CMD ... -p ${PORT}` で `$PORT` を listen する作りなので流用の下地はある。ただし **イメージに `ENV PORT=8080` が焼き込まれている**点に注意。Vercel はデフォルトで **ポート 80** にルーティングするため、Vercel 版では **Vercel 側の `PORT` を 8080 に設定する**か、**イメージの `ENV PORT` 既定値を外して Vercel の 80 を通す**必要がある（そのまま流用するとビルドは通ってもトラフィックが届かない）。

### 課金モデルの違い（Cloud Run と比較）

| | GCP Cloud Run | Vercel Fluid compute |
|---|---|---|
| 基本料金 | **なし**（従量のみ） | プラン必須。**Hobby=無料（非商用・上限あり）** / Pro=$20/人・月 |
| CPU 課金 | vCPU 秒。**リクエスト処理中はずっと**（DB 待ちも含む） | **Active CPU $0.128/時**。**コード実行中だけ**（I/O 待ちは課金停止） |
| メモリ課金 | GiB 秒 | Provisioned Memory $0.0106/GB時。**リクエスト処理中は I/O 待ちも含めて課金**（最後の in-flight リクエストが終わるまで） |
| リクエスト | 100万 $0.40（月200万まで無料） | Invocations 100万 $0.60 |
| 無料枠 | **月 18万 vCPU秒 / 36万 GiB秒 / 200万 req** | Hobby プラン枠内 |
| アイドル | 0円（scale to zero） | リクエスト間は 0 |

> ⚠️ **単位に注意**: Cloud Run は「**秒**」課金、Vercel は「**時**」課金で表記が異なる。ざっくり横並び比較するなら Vercel の「/時」を **3600 で割る**と「/秒」換算になる（例: Active CPU $0.128/時 ≒ $0.0000356/秒）。

- **低トラフィックの本プロジェクトでは、使用量自体はどちらも誤差レベルに安い。** 勝敗は「無料枠と基本料金」で決まる。
- Vercel は **CPU について I/O 待ちを課金しない**のが強みで、DB(Neon)・Google API 待ちが多い Rails と相性は悪くない。**ただしメモリ（Provisioned Memory）はリクエスト処理が続く限り I/O 待ちも含めて課金される**ため、「I/O 待ちは一切タダ」ではない点に注意。さらに **商用運用は Hobby 不可 → Pro $20/月の下駄**が要る。

### 結論: 現状維持（変更なし）

- 方針は **「Vercel は無料(Hobby)で使う」**。Hobby は非商用・個人利用向けで、常時稼働のバックエンドを載せる用途には枠・規約的に不向き。
- よって **Rails は引き続き GCP Cloud Run**（無料枠＋基本料金なしで低トラフィックなら実質 0 円、かつデプロイ定義が既に揃っている）。**現行構成（Vercel=フロント / Cloud Run=Rails / Neon=DB）から変更しない。**
- **将来 Vercel が Pro 前提になった場合のみ**（フロントで $20/月を払うなら追加固定費なしで載る）、「全部 Vercel に集約して運用を一本化」を再検討する余地あり。

### 「全部 Vercel」にする場合に必要だった対応（＝今回は見送り）

再検討時のためにメモとして残す:

1. `Dockerfile.vercel` を追加（既存 `Dockerfile` ベース。default PORT を 80 に合わせる）。
2. **画像アップロードを外部ストレージへ**（コンテナはステートレス＝ローカル保存は消える）。元々 GCS 化が前提（runbook「7. 将来対応」）なので方針は同じ。
3. **Host Authorization に Vercel ドメインを追加**（`config/environments/production.rb` は現状 `*.run.app` のみ自動許可）。`*.vercel.app` / カスタムドメインは `APP_HOSTS` で許可する必要あり。
4. 同一ドメイン配下にまとめられれば CORS を不要化できる（別ドメインなら現行の `FRONTEND_URL` ベースの CORS のまま）。

### リポジトリ分割について

- フロント(`matcha-to-jinja`) と バックエンド(`greentea_temple`) が **別リポジトリなのは標準的な構成で、デプロイ先が Vercel / GCP どちらでも問題ない**。
- Vercel でも **1 リポジトリ = 1 プロジェクト**として独立にデプロイでき、モノレポ化は不要。
- つなぎ込み（フロントに API URL を env で渡す / バックエンドは CORS・`APP_HOSTS` でフロントを許可）は **既に実装済み**（`config/initializers/cors.rb`・`production.rb`）。分割のままで完結する。
