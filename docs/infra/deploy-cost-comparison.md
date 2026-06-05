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
| Railway | $5/月クレジット内で収まれば実質無料 | ほぼなし | 低 | 中 | ○ |

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

- **¥0 を守るなら**: `min-instance=0` のまま、**Cloud Scheduler で数分おきに `/api/v1/health` を叩いてウォーム維持**（ヘルスチェックは無料枠内に収まる）。受け入れ条件「5 秒以内」をこれで担保する。
- **確実に消したいなら**: `min-instance=1`（常時 1 台起動）。ただし常時課金で **月 ¥800 前後**になるため、¥0 方針とはトレードオフ。
- 起動高速化: `bootsnap` 有効化（導入済み）、本番 assets は **ビルド時に precompile**（実行時に走らせない）、不要 initializer の見直し。
- `config/puma.rb` の `WEB_CONCURRENCY` / スレッド数を Cloud Run の CPU1 / 512Mi に合わせて控えめに。

### 4-2. Neon 無料枠（0.5GB 上限・オートサスペンド）

- **画像を DB に入れない**（元方針どおり GCS へ）。DB は構造化データのみで当面 0.5GB に十分収まる。
- 接続は **Pooled connection + SSL 必須**（`DATABASE_URL` に `?sslmode=require` 等）。Cloud Run の同時実行で接続枯渇しないよう pooler 経由にする。
- オートサスペンドからの復帰遅延は、4-1 のウォーム維持と合わせれば体感を抑えられる。
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

- matcha-to-jinja: `docs/migration-plan.md`（「環境構成」「GCP Cloud Run デプロイ手順」「Neon PostgreSQL セットアップ」）
- 関連 issue: #113 〜 #118（API 化 → デプロイ）
