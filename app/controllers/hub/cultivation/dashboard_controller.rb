# frozen_string_literal: true

module Hub
  module Cultivation
    # Dashboard controller for the Cultivation namespace
    class DashboardController < BaseController
      def index
        # Cultivation dashboard logic here
        @farm = Current.farm
        @recent_operations = [] # Will be populated with recent operations
      end
    end
  end
end
