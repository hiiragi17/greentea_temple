Rails.application.routes.draw do
  namespace :api do
    namespace :v1 do
      get 'health', to: 'health#show'

      delete 'auth/logout', to: 'auth#destroy'
      post 'auth/:provider', to: 'auth#create', constraints: { provider: /line|google/ }
      get 'current_user', to: 'current_user#show'

      resources :greenteas, only: %i[index show]
      resources :temples, only: %i[index show]
      resources :genres, only: %i[index]
      resources :areas, only: %i[index]

      get 'nearby', to: 'nearby#search'

      resources :routes, only: %i[index show create update destroy]

      resources :greentea_likes, only: %i[index create destroy]
      resources :temple_likes, only: %i[index create destroy]
      resources :greenteacomments, only: %i[index create destroy]
      resources :templecomments, only: %i[index create destroy]

      # 管理用 API（admin 権限必須）。抹茶店・神社の CRUD とコメントモデレーション。
      namespace :admin do
        resources :greenteas, only: %i[create update destroy]
        resources :temples, only: %i[create update destroy]
        resources :comments, only: %i[index]
        resources :greenteacomments, only: %i[destroy]
        resources :templecomments, only: %i[destroy]
      end
    end

    match '*unmatched', to: 'v1/base#route_not_found', via: :all
  end

  namespace :admin do
      resources :users
      resources :temple_likes
      resources :temple_areas
      resources :temples
      resources :greentea_likes
      resources :greentea_genres
      resources :greenteas
      resources :genres
      resources :authentications
      resources :areas
      resources :greenteacomments
      resources :templecomments

      root to: "users#index"
    end

  root 'static_pages#top'
  get 'terms_of_service', to: 'static_pages#terms_of_service'
  get 'privacy_policy', to: 'static_pages#privacy_policy'

  # PWA: Rails 8 標準の Rails::PwaController で app/views/pwa/* を動的配信する
  # （manifest はレイアウトから pwa_manifest_path(format: :json) で参照）
  get 'manifest', to: 'rails/pwa#manifest', as: :pwa_manifest
  get 'service-worker', to: 'rails/pwa#service_worker', as: :pwa_service_worker

  resources :users

  get 'login', to: 'user_sessions#new'
  post 'login', to: 'user_sessions#create'
  delete 'logout', to: 'user_sessions#destroy'

  post 'oauth/callback', to: 'oauths#callback'
  get 'oauth/callback', to: 'oauths#callback'
  get 'oauth/:provider', to: 'oauths#oauth', as: :auth_at_provider

  # --- #136 段階1: 旧 Web フロントのルーティング無効化（410 Gone） ---
  # 抹茶店／神社の閲覧・いいね・口コミ・現在地検索は API(/api/v1) と Next.js
  # フロント（matcha-to-jinja）へ移行済みのため、これらの HTML ルートは 410 を返す。
  # まず無効化のみ行い、コントローラ／ビュー本体の削除は後続段階（#136 段階2・3）で実施する。
  # レイアウト等の残存ビューが参照する名前付きヘルパーは維持し、描画を壊さない。
  get 'greenteas/greentea_likes', to: 'legacy_routes#gone', as: :greentea_likes_greenteas
  get 'greenteas', to: 'legacy_routes#gone', as: :greenteas
  get 'greenteas/:id', to: 'legacy_routes#gone', as: :greentea
  match 'greenteas/*path', to: 'legacy_routes#gone', via: :all

  get 'temples/temple_likes', to: 'legacy_routes#gone', as: :temple_likes_temples
  get 'temples', to: 'legacy_routes#gone', as: :temples
  get 'temples/:id', to: 'legacy_routes#gone', as: :temple
  match 'temples/*path', to: 'legacy_routes#gone', via: :all

  match 'greentea_likes(/*path)', to: 'legacy_routes#gone', via: :all
  match 'temple_likes(/*path)', to: 'legacy_routes#gone', via: :all
  match 'greenteacomments(/*path)', to: 'legacy_routes#gone', via: :all
  match 'templecomments(/*path)', to: 'legacy_routes#gone', via: :all

  get 'current_location', to: 'legacy_routes#gone', as: :current_location
  match 'current_location/*path', to: 'legacy_routes#gone', via: :all

  get '*path', to: 'application#render_404'
end
