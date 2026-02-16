Rails.application.routes.draw do
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

  resources :users

  get 'login', to: 'user_sessions#new'
  post 'login', to: 'user_sessions#create'
  delete 'logout', to: 'user_sessions#destroy'

  post 'oauth/callback', to: 'oauths#callback'
  get 'oauth/callback', to: 'oauths#callback'
  get 'oauth/:provider', to: 'oauths#oauth', as: :auth_at_provider

  resources :greenteas, only: %i[index show] do
    resources :greenteacomments, only: %i[index create edit update destroy], shallow: true
    collection do
      get :greentea_likes
    end
  end

  resources :greentea_likes, only: %i[create destroy]

  resources :temples, only: %i[index show] do
    resources :templecomments, only: %i[index create edit update destroy], shallow: true
    collection do
      get :temple_likes
    end
  end

  resources :temple_likes, only: %i[create destroy]

  get 'current_location', to:'current_location#search'
  get 'current_location/result', to:'current_location#result'

  # API
  namespace :api do
    namespace :v1 do
      # 読み取り系
      resources :greenteas, only: %i[index show]
      resources :temples, only: %i[index show]
      resources :areas, only: %i[index]
      resources :genres, only: %i[index]

      # 近隣検索
      get 'nearby', to: 'nearby#search'

      # 認証
      post 'auth/:provider/callback', to: 'auth#callback'
      delete 'auth/logout', to: 'auth#logout'
      get 'current_user', to: 'current_user#show'

      # いいね
      resources :greenteas, only: [] do
        resources :likes, only: %i[index create], controller: 'greentea_likes'
        delete 'likes', to: 'greentea_likes#destroy'
        resources :comments, only: %i[index create], controller: 'greenteacomments'
      end
      resources :temples, only: [] do
        resources :likes, only: %i[index create], controller: 'temple_likes'
        delete 'likes', to: 'temple_likes#destroy'
        resources :comments, only: %i[index create], controller: 'templecomments'
      end

      # コメント削除
      delete 'comments/greentea/:id', to: 'greenteacomments#destroy', as: :destroy_greenteacomment
      delete 'comments/temple/:id', to: 'templecomments#destroy', as: :destroy_templecomment
    end
  end

  get '*path', to: 'application#render_404'
end
