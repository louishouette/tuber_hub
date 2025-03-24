# frozen_string_literal: true

# Concern for controllers that require admin authorization
module AdminAuthorization
  extend ActiveSupport::Concern

  included do
    before_action :authorize_admin_access
    skip_before_action :authorize_namespace_access, raise: false
  end

  private

  # Use standard Pundit pattern to check if the user is an admin
  def authorize_admin_access
    # Use the action name to determine which policy method to call
    # This will call index?, show?, etc. based on the current controller action
    # Handle search actions the same as index actions for policy checks
    action_method = action_name == 'search' ? 'index' : action_name
    authorize :admin, "#{action_method}?".to_sym, policy_class: AdminPolicy
  rescue Pundit::NotAuthorizedError
    flash[:alert] = "You must be an administrator to access this area"
    redirect_to hub_path, status: :forbidden
  end
  
  # Override the pundit user method to ensure we always use Current.user
  def pundit_user
    Current.user
  end
end
