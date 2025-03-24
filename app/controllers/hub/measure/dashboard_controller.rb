# frozen_string_literal: true

module Hub
  module Measure
    # Dashboard controller for the Measure namespace
    class DashboardController < BaseController
      def index
        # Measure dashboard logic here
        @farm = Current.farm
        @recent_observations = [] # Will be populated with recent observations
      end
    end
  end
end
