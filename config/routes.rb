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
    # Notification routes
    resources :notifications, only: [:index, :create] do
      collection do
        get :unread
        get :count
        get :items
        post :mark_all_as_read
      end
      member do
        get :toast
        patch :read
        patch :dismiss
        patch :displayed
      end
    end

    namespace :admin do
      # User management
      resources :users do
        member do
          get 'assign_roles'
          post 'assign_roles'
          patch 'toggle_active'  # For blocking/unblocking users
        end
        collection do
          get 'roles/:role_id', to: 'users#by_role', as: :by_role
        end
      end
      
      # Role management
      resources :roles do
        member do
          get 'users', to: 'roles#users', as: :users
          get 'assign_permissions'
          post 'assign_permissions'
        end
      end
      
      # Permission management
      resources :permissions, only: [:index, :show] 
      post 'permissions/refresh', to: 'permissions#refresh', as: 'refresh_admin_permissions'
    end
    
    # Core namespace for main elements
    namespace :core do
      resources :farms
      resources :seasons
      resources :productions
    end
    
    # Cultivation namespace and sub-namespaces
    namespace :cultivation do
      resources :irrigations
      resources :fertilizations
      resources :treatments
      resources :plantings
      resources :findings
      resources :tilings
      resources :mowings
      resources :prunnings
      
      namespace :irrigation do
        resources :sectors
        resources :admissions
        resources :tertiaries
        resources :primaries
        resources :secondaries
        resources :dispensers
      end
      
      namespace :fertilization do
        resources :formulas
        resources :tools
      end
      
      namespace :treatment do
        resources :families
        resources :tools
        resources :formulas
      end
      
      namespace :planting do
        resources :orchards
        resources :parcels
        resources :rows
        resources :locations
        resources :species
        resources :nurseries
        resources :inoculations
      end
      
      namespace :harvest do
        resources :runs
        resources :dogs
        resources :sectors
      end
      
      namespace :tiling do
        resources :tools
      end
      
      namespace :mowing do
        resources :tools
      end
      
      namespace :prunning do
        resources :architectures
        resources :pruners
      end
    end
    
    # Measure namespace and sub-namespaces
    namespace :measure do
      resources :observations
      
      namespace :observation do
        resources :types
      end
      
      resources :soil_analyses
      resources :soil_resistivities
      resources :soil_moistures
      resources :meteorologicals
      resources :plant_electrophysiologies
      resources :multispectrals
    end
    get "/", to: "home#index"
  end

  # The namespace directive already handles both /namespace and /namespace/ routes

  # Root path (/)  - pointing to the public namespace for now
  root "public/home#index"
end
