Rails.application.routes.draw do
  mount RailsAdmin::Engine => '/admin', as: 'rails_admin'
  root 'static_pages#top'

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

  resources :temples, only: %i[index show] 
  resources :users
  get 'current_location', to:'current_location#search'
  get 'current_location/result', to:'current_location#result'
end
