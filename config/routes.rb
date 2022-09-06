Rails.application.routes.draw do
  root 'static_pages#top'
  resources :greenteas do
  end
  resources :temples do
  end
  get 'current_location', to:'current_location#search'
  get 'current_location/result', to:'current_location#result'
end
