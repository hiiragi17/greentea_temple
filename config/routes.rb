Rails.application.routes.draw do
  root 'static_pages#top'
  resources :greenteas do
  end
  resources :temples do
  end
end
