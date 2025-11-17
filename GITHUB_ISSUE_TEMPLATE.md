# Rails API化 プロジェクト計画 #plan-rails-api-conversion

## 概要
Greentea Temple を **Rails API + Next.js** アーキテクチャへマイグレーションするための総合計画

**関連PR**: [詳細設計書PR](https://github.com/hiiragi17/greentea_temple/pull/new/claude/plan-rails-api-conversion-016MtnxfmJXFjRKFiV7jfFf9)

---

## 現状
- **バックエンド**: Rails 7.0.3（MVC + Views）
- **フロントエンド**: HTML/ERB + Hotwire（Turbo/Stimulus）
- **スタイル**: Tailwind CSS + DaisyUI
- **認証**: Sorcery（OAuth: Twitter/LINE）

## 目標状態
```
Next.js Frontend                Rails API Backend
┌──────────────────┐          ┌──────────────────┐
│ React + TS       │◄────────►│ JSON API         │
│ Tailwind + DaisyUI    REST/  │ Sorcery Auth     │
│ Vercel Deploy    │  JSON    │ PostgreSQL       │
└──────────────────┘          └──────────────────┘
```

---

## 計画の全体像

### Phase 1: 基盤整備（1-2週間）
- Rails APIモード設定
- CORS設定
- JSON レスポンスフォーマット統一
- 認証・認可システムのAPI化
- エラーハンドリング統一

### Phase 2: APIエンドポイント開発（2-3週間）
- ユーザー関連API
- 検索・一覧API（Greentea/Temple）
- 詳細表示API
- 位置情報API
- いいね/コメント管理API

### Phase 3: Next.jsプロジェクト構築（1-2週間）
- Next.js 14プロジェクト初期化
- 認証フロー実装
- API Client層構築
- コンポーネント設計

### Phase 4: フロントエンド実装（3-4週間）
- 検索・一覧ページ
- 詳細ページ
- ユーザーページ
- コメント・いいね機能

### Phase 5: テスト・最適化（1-2週間）
- エンドツーエンドテスト
- パフォーマンス最適化
- SEO最適化

### Phase 6: デプロイ・移行（1週間）
- ステージング環境構築
- 本番環境テスト
- DNS切り替え

---

## 主要なAPI設計

### ベースURL
```
https://api.matcha-to-jinja.com/api/v1
```

### 認証
```
Authorization: Bearer {JWT_TOKEN}
```

### エンドポイント例

#### 抹茶スイーツ
```
GET    /greenteas              # 一覧（検索）
GET    /greenteas/:id          # 詳細
POST   /greenteas/:id/comments # コメント追加
POST   /greenteas/:id/like     # いいね追加
DELETE /greenteas/:id/like     # いいね削除
```

#### 神社仏閣
```
GET    /temples                # 一覧（検索）
GET    /temples/:id            # 詳細
POST   /temples/:id/comments   # コメント追加
POST   /temples/:id/like       # いいね追加
DELETE /temples/:id/like       # いいね削除
```

#### 認証・ユーザー
```
POST   /auth/oauth/:provider   # OAuth初期化
POST   /auth/callback          # OAuth コールバック
POST   /auth/logout            # ログアウト
GET    /auth/me                # 現在ユーザー情報
```

#### 位置情報
```
GET    /locations/nearby       # 現在地周辺
  Query: latitude, longitude, radius (default: 1500m), type
GET    /locations/geocode      # 住所から座標
  Query: address
```

---

## リスク・懸念点と対策

### 高リスク
| 項目 | 対策 |
|------|------|
| OAuth認証の複雑性 | Phase 1で十分な検証、テスト |
| 既存ユーザーの混乱 | Cookie/JWT両対応、リダイレクト設定 |
| SEO損失 | Next.js SSG/SSR活用、XML Sitemap |

### 中リスク
| 項目 | 対策 |
|------|------|
| 既存リンク切れ | リダイレクトマップ作成 |
| パフォーマンス低下 | API最適化、キャッシング、CDN |
| 管理画面の再構築 | Admin UI フレームワーク検討 |

---

## 技術的決定事項

### 認証方式: **JWT推奨**
- ステートレス設計（スケーリング容易）
- SPA・モバイル対応
- リフレッシュトークン実装可能

### DB継続: PostgreSQL
- 既存データ保全
- Full-text Search対応
- PostGIS対応可能性

### フロントエンド: Next.js 14+
- SEO（SSG/SSR）
- ホットリロード、TypeScript標準
- Vercelデプロイ

### スタイル: Tailwind CSS + DaisyUI 継続
- 既存資産活用
- 開発速度向上

---

## 期待される成果

✅ **定量的効果**
- APIレスポンスタイム: < 500ms
- フロントエンド軽量化: -30% バンドルサイズ
- TTL (Time to Largest Contentful Paint): < 1.5s

✅ **定性的効果**
- フロントエンド・バックエンド独立開発可能
- モバイルアプリ対応への道開き
- SEO改善（SSG/SSR活用）
- スケーラビリティ向上

---

## 次のステップ

1. **Phase 1 タスク分解** → 細粒度のGitHub Issues作成
2. **開発チーム結成** → バックエンド/フロントエンドチーム
3. **API設計書最終化** → OpenAPI仕様書作成
4. **開発環境構築** → Rails API + Next.js ローカル環境

---

## 参考資料

- [詳細設計書](/RAILS_API_CONVERSION_PLAN.md)
- [Rails API only Applications](https://guides.rubyonrails.org/api_app.html)
- [Next.js Documentation](https://nextjs.org/docs)
- [OpenAPI Specification](https://spec.openapis.org/oas/v3.1.0)

---

## チェックリスト

### Phase 1: 基盤整備
- [ ] Rails APIモード設定
- [ ] CORS設定（rack-cors gem）
- [ ] レスポンスフォーマット統一
- [ ] エラーハンドリング実装
- [ ] 認証ロジックのAPI化
- [ ] OpenAPI文書作成

### Phase 2-6: 実装フェーズ
- [ ] APIエンドポイント完成
- [ ] Next.jsプロジェクト構築
- [ ] 全ページ実装
- [ ] テスト実施
- [ ] ステージング検証
- [ ] 本番環境デプロイ

---

## Labels（推奨）
- `type: planning` - 計画段階
- `area: architecture` - アーキテクチャ
- `priority: high` - 優先度高
- `status: in-progress` - 進行中

## Assignee
@hiiragi17

## Milestone
`Rails API Conversion` (新規作成推奨)
