Rails.application.routes.draw do
  # Authentication routes
  get "/login", to: "sessions#new", as: :login
  post "/login", to: "sessions#create", as: :session
  delete "/logout", to: "sessions#destroy", as: :logout
  resources :passwords, param: :token

  # Health check - Can be used by load balancers and uptime monitors
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Clean URLs for public pages (no namespace in URL but controllers are in public/ namespace)
  get "/shop", to: "public/shop#index", as: :shop
  get "/blog", to: "public/blog#index", as: :blog
  get "/news", to: "public/news#index", as: :news
  get "/about", to: "public/about#index", as: :about
  get "/contact", to: "public/contact#index", as: :contact
  get "/jobs", to: "public/job#index", as: :job

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
