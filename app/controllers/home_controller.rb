class HomeController < ApplicationController
  # Allow unauthenticated access to the home page
  allow_unauthenticated_access only: :index
  
  def index
    # If user is logged in, show user-specific dashboard
    # Otherwise, show landing page
  end
end
