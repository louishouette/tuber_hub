class PublicController < ApplicationController
  # Base controller for the public namespace
  layout 'public/application'
  
  # Allow unauthenticated access to all public pages by default
  # Override in child controllers if needed
  allow_unauthenticated_access
end
