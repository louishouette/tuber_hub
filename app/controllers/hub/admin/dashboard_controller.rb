# frozen_string_literal: true

module Hub
  module Admin
    # Dashboard controller for the Admin namespace
    class DashboardController < BaseController
      def index
        # Admin dashboard logic here
        @recent_users = policy_scope(Hub::Admin::User).order(created_at: :desc).limit(5)
        @recent_farms = policy_scope(Hub::Admin::Farm).order(created_at: :desc).limit(5)
        # Skip policy_scope for dashboard stats that don't have a model
        skip_policy_scope
      end
    end
  end
end
