class HubController < ApplicationController
  # Base controller for the hub namespace
  layout 'hub/application'
  
  # Require authentication for all hub pages by default
  # Override in child controllers if needed
  # No call to allow_unauthenticated_access means authentication is required
end
