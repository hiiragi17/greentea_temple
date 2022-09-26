Rails.application.routes.draw do
  mount RailsAdmin::Engine => '/admin', as: 'rails_admin'
  root 'static_pages#top'
  resources :greenteas, only: %i[index show]
  resources :temples, only: %i[index show] 
  get 'current_location', to:'current_location#search'
  get 'current_location/result', to:'current_location#result'
end
