# Greentea Temple - Rails API化 詳細設計書

## 1. 概要

### 目的
現在のRails + Hotwire モノリシック構成から、**Rails API + Next.js** のマイクロサービス風アーキテクチャへの移行

### 現状
- **バックエンド**: Rails 7.0.3（MVC + Views）
- **フロントエンド**: HTML/ERB + Hotwire（Turbo/Stimulus）
- **スタイル**: Tailwind CSS + DaisyUI
- **認証**: Sorcery（OAuth: Twitter/LINE）

### 目標構成
```
┌─────────────────────┐          ┌──────────────────┐
│   Next.js 14+       │          │  Rails API 7+    │
│  (Frontend)         │◄────────►│  (Backend)       │
│ - React            │  REST/   │ - JSON API       │
│ - TypeScript       │  GraphQL │ - Sorcery Auth   │
│ - Tailwind         │          │ - DB: PostgreSQL │
└─────────────────────┘          └──────────────────┘
```

---

## 2. 現状分析

### 2.1 既存機能リスト

#### Core機能
- ✅ 抹茶スイーツ店の検索・表示
- ✅ 神社仏閣の検索・表示
- ✅ キーワード検索（Ransack）
- ✅ ジャンル/地域絞り込み
- ✅ 位置情報ベース検索（半径1.5km）
- ✅ 現在地からの検索
- ✅ いいね機能（greentea_likes, temple_likes）
- ✅ コメント機能（greenteacomments, templecomments）
- ✅ OAuth認証（Twitter/LINE）
- ✅ ユーザー管理
- ✅ 管理画面（Administrate）

#### サポート機能
- ✅ 画像アップロード（CarrierWave + MiniMagick）
- ✅ Geocoding（住所 → 緯度経度）
- ✅ Geolocation API（ブラウザの位置情報）
- ✅ Google Maps連携（gon gem）
- ✅ SNSシェア（Twitter/LINE）
- ✅ 多言語対応（日本語がデフォルト）
- ✅ Pagination（Kaminari）

### 2.2 技術的負債/改善機会

#### 現状の問題点
| 項目 | 現状 | 改善後 |
|------|------|--------|
| フロントエンド更新 | Rails リリース周期 | Next.js 独立リリース |
| SEO最適化 | 限定的 | SSG/SSR対応 |
| API拡張性 | ビューに依存 | JSON API標準化 |
| フロントエンド開発速度 | Rails の制約 | React 独立開発 |
| デプロイ | モノリシック | 独立デプロイ可能 |
| スケーラビリティ | 共存 | 独立スケーリング |

---

## 3. マイグレーション戦略

### 3.1 段階的マイグレーションアプローチ

#### Phase 1: 基盤整備（1-2週間）
- [ ] Rails APIモード設定
- [ ] CORS設定
- [ ] JSON API レスポンスフォーマット標準化
- [ ] 認証・認可システムのAPI化（JWT or Session）
- [ ] エラーハンドリング統一
- [ ] API文書化（OpenAPI/Swagger）

#### Phase 2: APIエンドポイント開発（2-3週間）
- [ ] ユーザー関連API
- [ ] 検索・一覧API（Greentea/Temple）
- [ ] 詳細表示API
- [ ] 位置情報API
- [ ] いいね/コメント管理API
- [ ] 管理画面API

#### Phase 3: Next.jsプロジェクト構築（1-2週間）
- [ ] Next.js 14プロジェクト初期化
- [ ] 認証フロー実装
- [ ] API Client層構築
- [ ] コンポーネント設計
- [ ] Tailwind CSS設定

#### Phase 4: フロントエンド実装（3-4週間）
- [ ] 検索・一覧ページ
- [ ] 詳細ページ
- [ ] ユーザーページ
- [ ] コメント機能
- [ ] いいね機能
- [ ] 管理画面（オプション）

#### Phase 5: テスト・最適化（1-2週間）
- [ ] エンドツーエンドテスト
- [ ] パフォーマンス最適化
- [ ] SEO最適化
- [ ] モバイル対応確認
- [ ] ブラウザ互換性確認

#### Phase 6: デプロイ・移行（1週間）
- [ ] ステージング環境構築
- [ ] 本番環境テスト
- [ ] DNS切り替え
- [ ] リダイレクト設定
- [ ] モニタリング

---

## 4. APIエンドポイント設計

### 4.1 ベースURL
```
https://api.matcha-to-jinja.com/api/v1
```

### 4.2 認証
```
- Authentication: Bearer {JWT_TOKEN} または Cookie-based Session
- CORS: https://app.matcha-to-jinja.com を許可
```

### 4.3 エンドポイント一覧

#### 認証・ユーザー
```
POST   /auth/oauth/:provider         # OAuth初期化（Redirect）
POST   /auth/callback                 # OAuth コールバック処理
POST   /auth/logout                   # ログアウト
GET    /auth/me                       # 現在のユーザー情報
GET    /users/:id                     # ユーザー詳細
PATCH  /users/:id                     # ユーザー更新
```

#### 抹茶スイーツ関連
```
GET    /greenteas                     # 一覧（検索・ページネーション）
GET    /greenteas/:id                 # 詳細
GET    /greenteas/:id/comments        # コメント一覧
POST   /greenteas/:id/comments        # コメント追加
PATCH  /greenteacomments/:id          # コメント編集
DELETE /greenteacomments/:id          # コメント削除
POST   /greenteas/:id/like            # いいね追加
DELETE /greenteas/:id/like            # いいね削除
GET    /greenteas/:id/liked           # いいね済みか確認
```

#### 神社仏閣関連
```
GET    /temples                       # 一覧（検索・ページネーション）
GET    /temples/:id                   # 詳細
GET    /temples/:id/comments          # コメント一覧
POST   /temples/:id/comments          # コメント追加
PATCH  /templecomments/:id            # コメント編集
DELETE /templecomments/:id            # コメント削除
POST   /temples/:id/like              # いいね追加
DELETE /temples/:id/like              # いいね削除
GET    /temples/:id/liked             # いいね済みか確認
```

#### 位置情報
```
GET    /locations/nearby              # 現在地周辺の施設
  Query: latitude, longitude, radius (default: 1500m), type (greentea|temple|all)
GET    /locations/geocode             # 住所から座標取得
  Query: address
GET    /locations/reverse-geocode      # 座標から住所取得
  Query: latitude, longitude
```

#### マスターデータ
```
GET    /genres                        # スイーツジャンル一覧
GET    /areas                         # 地域一覧
```

### 4.4 レスポンスフォーマット

#### 成功レスポンス (200/201)
```json
{
  "status": "success",
  "data": {
    "id": 1,
    "name": "京都高瀬川スイーツ",
    // ... その他フィールド
  }
}
```

#### ページネーション付き (200)
```json
{
  "status": "success",
  "data": [
    { "id": 1, "name": "..." },
    { "id": 2, "name": "..." }
  ],
  "pagination": {
    "current_page": 1,
    "total_pages": 5,
    "total_count": 45,
    "per_page": 10
  }
}
```

#### エラーレスポンス (4xx/5xx)
```json
{
  "status": "error",
  "error": {
    "code": "RECORD_NOT_FOUND",
    "message": "抹茶スイーツが見つかりません",
    "details": {
      "resource": "Greentea",
      "id": 999
    }
  }
}
```

### 4.5 クエリパラメータ設計

#### 検索
```
GET /greenteas?q=抹茶ラテ&genres=1,2&page=1&per_page=10&sort=-created_at
```

#### フィルタリング
```
GET /temples?areas=1,2,3&closed=false
```

#### 位置情報
```
GET /locations/nearby?latitude=35.0116&longitude=135.7681&radius=1500&type=all&per_page=20
```

---

## 5. データベーススキーマ変更

### 5.1 テーブル構成（変更なし）
既存のテーブル構造はそのまま利用

### 5.2 新規追加カラム候補

#### users テーブル
```ruby
# 既存
- id, name, role, created_at, updated_at

# 追加候補
- last_login_at: DateTime（最終ログイン日時）
- last_activity_at: DateTime（最終活動日時）
```

#### greenteas / temples テーブル
```ruby
# 既存
- id, name, description, address, latitude, longitude,
  access, business_hours, holiday, phone_number, homepage,
  img, closed, created_at, updated_at

# 追加候補
- view_count: Integer（閲覧数）- キャッシュ用
- average_rating: Float（平均評価）- 将来の評価機能向け
```

#### greenteacomments / templecomments テーブル
```ruby
# 既存
- id, greentea_id/temple_id, user_id, body, created_at, updated_at

# 追加候補
- status: enum（公開/非公開/削除）- ソフト削除向け
- helpful_count: Integer（役立つ度数）- ソート用
```

### 5.3 新規テーブル（オプション）

#### api_keys テーブル（外部API連携向け）
```ruby
create_table :api_keys do |t|
  t.references :user, null: false
  t.string :key, null: false, index: { unique: true }
  t.string :name
  t.datetime :last_used_at
  t.datetime :expires_at
  t.timestamps
end
```

#### audit_logs テーブル（監査ログ）
```ruby
create_table :audit_logs do |t|
  t.references :user
  t.string :action
  t.string :resource_type
  t.integer :resource_id
  t.text :changes
  t.string :ip_address
  t.timestamps
end
```

---

## 6. 認証・認可の設計

### 6.1 認証方式の選択

#### Option A: JWT ベース（推奨）
```
メリット:
- ステートレス（スケーリング容易）
- SPA・モバイルアプリ対応
- リフレッシュトークン実装可能

デメリット:
- トークン無効化が難しい（ブラックリスト必要）
```

#### Option B: Cookie-based Session（既存継続）
```
メリット:
- CSRF保護が容易
- シンプル（既存実装流用可）

デメリット:
- ステートフル（スケーリング課題）
- SPA対応が複雑
```

**推奨**: JWT ベースへの移行（OAuth accessToken をそのまま利用）

### 6.2 認証フロー

#### OAuth（Twitter/LINE）
```
1. ユーザーが Next.js の「ログイン」をクリック
2. Next.js → Rails API: POST /auth/oauth/twitter
3. Rails → OAuth Provider（Twitter）
4. OAuth Provider → Rails: Callback
5. Rails: ユーザー作成/更新、JWT生成
6. Rails → Next.js: Redirect to app.matcha-to-jinja.com/callback?token=xxx
7. Next.js: localStorage に JWT保存、ホームへリダイレクト
```

### 6.3 権限管理

```
Role: general | admin

エンドポイント別:
- 公開: /greenteas, /temples, /locations（ログイン不要）
- ユーザー限定: /greenteas/:id/comments (POST), /like (POST/DELETE)
- 管理者限定: /admin/*, PATCH/DELETE（自分のコメント以外）
```

---

## 7. フロントエンド（Next.js）設計

### 7.1 プロジェクト構成

```
greentea_temple_web/
├── app/
│   ├── layout.tsx              # Root Layout
│   ├── page.tsx                # トップページ
│   ├── (auth)/
│   │   ├── login/page.tsx
│   │   └── callback/page.tsx
│   ├── (search)/
│   │   ├── greenteas/page.tsx
│   │   ├── greenteas/[id]/page.tsx
│   │   ├── temples/page.tsx
│   │   └── temples/[id]/page.tsx
│   ├── (location)/
│   │   └── nearby/page.tsx
│   ├── user/
│   │   ├── profile/page.tsx
│   │   └── likes/page.tsx
│   └── api/                    # Optional: Backend-like routes
│
├── components/
│   ├── common/
│   │   ├── Header.tsx
│   │   ├── Footer.tsx
│   │   └── Navigation.tsx
│   ├── search/
│   │   ├── SearchForm.tsx
│   │   ├── FilterPanel.tsx
│   │   └── ResultList.tsx
│   ├── detail/
│   │   ├── DetailCard.tsx
│   │   ├── CommentList.tsx
│   │   └── CommentForm.tsx
│   └── map/
│       └── MapComponent.tsx
│
├── lib/
│   ├── api-client.ts           # API通信
│   ├── auth.ts                 # 認証管理
│   ├── hooks.ts                # カスタムフック
│   └── utils.ts
│
├── styles/
│   └── globals.css             # Tailwind Config
│
├── public/
│   └── images/
│
└── package.json
```

### 7.2 主要技術スタック

```json
{
  "dependencies": {
    "react": "^18.3",
    "next": "^14.0",
    "typescript": "^5.x",
    "tailwindcss": "^3.x",
    "daisyui": "^4.x",
    "zustand": "^4.x",            // State Management
    "axios": "^1.x",              // HTTP Client
    "react-hook-form": "^7.x",    // Form Management
    "zod": "^3.x",                // Validation
    "leaflet": "^1.x",            // Map Library
    "react-leaflet": "^4.x",
    "next-auth": "^5.x",          // Auth (Optional)
    "swr": "^2.x"                 // Data Fetching
  }
}
```

### 7.3 認証フロー（詳細）

```typescript
// lib/auth.ts
export const loginWithOAuth = (provider: 'twitter' | 'line') => {
  // 1. Rails API にリダイレクト
  window.location.href = `${API_BASE}/auth/oauth/${provider}`;
};

export const handleCallback = async (token: string) => {
  // 2. トークンを localStorage に保存
  localStorage.setItem('access_token', token);
  // 3. ユーザー情報を取得
  const user = await apiClient.get('/auth/me');
  // 4. Store に保存
  authStore.setUser(user);
};

// API Client に自動的にトークンを付与
apiClient.defaults.headers.common['Authorization'] = `Bearer ${token}`;
```

### 7.4 API Client パターン

```typescript
// lib/api-client.ts
class ApiClient {
  private baseURL = process.env.NEXT_PUBLIC_API_URL;

  async get<T>(path: string, params?: any) {
    const response = await fetch(
      `${this.baseURL}${path}`,
      {
        headers: this.getAuthHeaders(),
        params
      }
    );
    return response.json() as T;
  }

  private getAuthHeaders() {
    const token = localStorage.getItem('access_token');
    return {
      'Authorization': token ? `Bearer ${token}` : '',
      'Content-Type': 'application/json'
    };
  }
}

export const apiClient = new ApiClient();
```

---

## 8. 開発ロードマップ

### マイルストーン

| Phase | 期間 | 成果物 |
|-------|------|--------|
| 基盤整備 | Week 1-2 | Rails API 構成、CORS、認証 |
| API開発 | Week 3-5 | 全エンドポイント実装 |
| Next.js構築 | Week 6-7 | プロジェクト初期化、認証 |
| フロントエンド実装 | Week 8-11 | UI/UX実装 |
| テスト・最適化 | Week 12-13 | E2E テスト、SEO |
| デプロイ・移行 | Week 14 | 本番環境への切り替え |

**想定期間**: 14週間（約3.5ヶ月）

---

## 9. リスク分析と対策

### 高リスク項目

| リスク | 影響度 | 対策 |
|--------|--------|------|
| OAuth認証の複雑性 | 高 | Phase 1で十分な検証、テスト |
| 既存ユーザーの移行 | 高 | Cookie/JWT 両対応、リダイレクト設定 |
| SEO損失 | 中 | Next.js SSG/SSR 活用、XML Sitemap |
| パフォーマンス低下 | 中 | API最適化、キャッシング、CDN活用 |
| 既存リンク切れ | 中 | リダイレクトマップ作成 |

### 中リスク項目

| リスク | 対策 |
|--------|------|
| 画像アップロード処理 | S3/GCS への移行、署名付きURL |
| Geocoding API 費用 | 指定回数内での実装、キャッシング |
| 管理画面の再構築 | Admin UI フレームワーク検討（React Admin等） |

---

## 10. 既存機能のマッピング

### 検索機能の実装方式変更

```
現状: Ransack（Rails Server-side）
移行後:
  - Backend: Rails API + Ransack（検索ロジック）
  - Frontend: Next.js + React Hook Form（UI）
  - 通信: axios で /api/v1/greenteas?q=xxx
```

### 位置情報機能の変更

```
現状:
  - ブラウザ Geolocation API → Rails コントローラ
  - Google Maps: gon gem で変数パス

移行後:
  - ブラウザ Geolocation API → Next.js State
  - Rails API: GET /locations/nearby にリクエスト
  - Frontend: leaflet-react で地図表示
```

### いいね機能の変更

```
現状: Turbo DOM更新（Server-side rendering）
移行後:
  - Frontend: React state 管理（Zustand）
  - API: POST/DELETE /greenteas/:id/like
  - 非同期処理でUI更新
```

### コメント機能の変更

```
現状: Turbo による部分更新
移行後:
  - API:
    - GET /greenteas/:id/comments（取得）
    - POST /greenteas/:id/comments（作成）
    - PATCH /greenteacomments/:id（編集）
    - DELETE /greenteacomments/:id（削除）
  - Frontend: React で CRUD処理
```

---

## 11. 並行開発計画

### Rails API チーム
1. API エンドポイント実装
2. エラーハンドリング・バリデーション
3. 認証・認可ロジック
4. テスト（RSpec）

### Next.js フロントエンド チーム
1. コンポーネント設計
2. UI/UX 実装（Tailwind + DaisyUI）
3. API Client 層
4. テスト（Jest + React Testing Library）

**同時進行**: Phase 2 の API 実装と Phase 3 の Next.js 初期化は平行実施

---

## 12. 実装チェックリスト

### Phase 1: 基盤整備
- [ ] Rails API モード への移行準備
- [ ] CORS 設定（gem: rack-cors）
- [ ] レスポンスフォーマット統一
- [ ] エラーハンドリング実装
- [ ] 認証ロジックのAPI化
- [ ] OpenAPI 文書作成

### Phase 2: APIエンドポイント
- [ ] ユーザー API
- [ ] 検索API（Greentea/Temple）
- [ ] 詳細API
- [ ] いいね API
- [ ] コメント API
- [ ] 位置情報 API
- [ ] マスターデータ API

### Phase 3: Next.js 構築
- [ ] プロジェクト初期化
- [ ] 認証フロー実装
- [ ] API Client 層
- [ ] レイアウト・ナビゲーション

### Phase 4: フロントエンド実装
- [ ] トップページ
- [ ] 検索ページ
- [ ] 詳細ページ
- [ ] ユーザーページ
- [ ] コメント機能
- [ ] いいね機能

### Phase 5: テスト・最適化
- [ ] E2E テスト
- [ ] パフォーマンス測定
- [ ] SEO 最適化
- [ ] アクセシビリティチェック

### Phase 6: デプロイ・移行
- [ ] ステージング環境テスト
- [ ] 本番環境構築
- [ ] ドメイン / DNS 切り替え
- [ ] モニタリング設定

---

## 13. ファイル構成例

### Rails API の新規作成 vs 既存改修

#### 推奨: 既存プロジェクトを API モード に改修
```ruby
# config/application.rb
config.api_only = true  # レスポンスは JSON のみ

# Gemfile から削除 (オプション)
gem 'webpacker'
gem 'sass-rails'
gem 'coffee-rails'

# 新規追加
gem 'rack-cors'
gem 'active_model_serializers'  # OR: blueprinter
```

#### 新規プロジェクト分離（別案）
```
/home/user/
├── greentea_temple          # 既存Rails（アーカイブ化）
├── greentea-temple-api      # Rails API（新規）
└── greentea-temple-web      # Next.js（新規）
```

**推奨**: 既存プロジェクトの改修（履歴保持、アセット再利用など）

---

## 14. 付録: 技術選定の判断基準

### JWT vs Session
- JWT 推奨理由:
  - SPA・モバイルアプリ対応
  - ステートレス（スケーリング容易）
  - 将来の API 拡張性

### PostgreSQL 継続利用
- 既存データ保全
- Full-text Search 対応
- PostGIS（将来の位置情報機能強化向け）

### Next.js 採用
- SEO（SSG/SSR）
- DX（ホットリロード、TS標準）
- エコシステム（Vercel デプロイなど）

### Tailwind CSS + DaisyUI 継続
- 既存スタイル資産活用
- 開発速度 (ユーティリティ優先)

---

## 15. 成功基準

- [ ] 全エンドポイントが API 経由で動作
- [ ] 既存機能の喪失なし
- [ ] パフォーマンス向上（TTL < 1.5s）
- [ ] SEO スコア維持・改善
- [ ] モバイル対応の強化
- [ ] デプロイの自動化
- [ ] ユーザーの混乱なし（リダイレクト・互換性）

---

## 参考資料

- [Rails API only Applications](https://guides.rubyonrails.org/api_app.html)
- [Next.js Documentation](https://nextjs.org/docs)
- [JWT Authentication Best Practices](https://tools.ietf.org/html/rfc8725)
- [CORS and Same-Origin Requests](https://developer.mozilla.org/en-US/docs/Web/HTTP/CORS)
- [OpenAPI Specification](https://spec.openapis.org/oas/v3.1.0)
