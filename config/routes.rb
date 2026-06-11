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

  get '*path', to: 'application#render_404'
end
