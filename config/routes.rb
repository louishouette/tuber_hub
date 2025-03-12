Rails.application.routes.draw do
  # Authentication routes
  resource :session
  resources :passwords, param: :token

  # Health check - Can be used by load balancers and uptime monitors
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Public namespace routes
  namespace :public do
    get "/", to: "home#index"
  end

  # Marketplace namespace routes
  namespace :marketplace do
    get "/", to: "home#index"
  end

  # Club namespace routes
  namespace :club do
    get "/", to: "home#index"
  end

  # Hub namespace routes
  namespace :hub do
    get "/", to: "home#index"
  end

  # The namespace directive already handles both /namespace and /namespace/ routes

  # Root path (/)  - pointing to the public namespace for now
  root "public/home#index"
end
