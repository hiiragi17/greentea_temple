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
    collection do
      get :greentea_likes
    end
  end

  resources :greentea_likes, only: %i[create destroy]

  resources :temples, only: %i[index show] do
    collection do
      get :temple_likes
    end
  end

  resources :temple_likes, only: %i[create destroy]

  get 'current_location', to:'current_location#search'
  get 'current_location/result', to:'current_location#result'
end
