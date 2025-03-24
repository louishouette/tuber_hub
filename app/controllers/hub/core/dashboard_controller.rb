# frozen_string_literal: true

module Hub
  module Core
    # Dashboard controller for the Core namespace
    class DashboardController < BaseController
      def index
        # Apply policy scoping to ensure proper authorization
        # This satisfies the Pundit requirement for index actions
        policy_scope(Hub::Admin::Farm)
        
        # Set current farm from Current object (not session directly)
        @farm = Current.farm
      end
    end
  end
end
