class ClubController < ApplicationController
  # Base controller for the club namespace
  layout 'club/application'
  
  # Require authentication for all club pages by default
  # Override in child controllers if needed
  # No call to allow_unauthenticated_access means authentication is required
end
