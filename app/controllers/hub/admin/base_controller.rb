# frozen_string_literal: true

module Hub
  module Admin
    class BaseController < Hub::BaseController
      before_action :authorize_admin_access
      before_action :set_default_view_path
      skip_before_action :authorize_namespace_access, raise: false
      
      private
      
      # Use standard Pundit pattern to check if the user is an admin
      def authorize_admin_access
        # Use the action name to determine which policy method to call
        # This will call index?, show?, etc. based on the current controller action
        authorize :admin, policy_class: AdminPolicy
      rescue Pundit::NotAuthorizedError
        flash[:alert] = "You must be an administrator to access this area"
        redirect_to hub_path, status: :forbidden
      end
      
      # Set the default view paths to include admin views
      def set_default_view_path
        prepend_view_path 'app/views/hub/admin'
      end
      
      # Override the pundit user method to ensure we always use Current.user
      def pundit_user
        Current.user
      end
    end
  end
end
