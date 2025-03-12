class MarketplaceController < ApplicationController
  # Base controller for the marketplace namespace
  layout 'marketplace/application'
  
  # Require authentication for all marketplace pages by default
  # Override in child controllers if needed
  # No call to allow_unauthenticated_access means authentication is required
end
