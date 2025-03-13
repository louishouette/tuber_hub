# app/controllers/concerns/authorization_concern.rb
module AuthorizationConcern
  extend ActiveSupport::Concern

  included do
    before_action :authorize_resource
  end

  protected

  def authorize_resource
    # Skip authorization if user is not logged in - let authenticate_user! handle it
    return unless current_user

    # Get controller and action names
    controller_name = params[:controller]
    action_name = params[:action]

    # Check if user has permission to access this controller/action
    unless user_authorized_for?(controller_name, action_name)
      flash[:alert] = "You do not have permission to access this resource"
      redirect_to root_path
    end
  end

  def user_authorized_for?(controller_name, action_name)
    # Always allow access to certain controllers/actions (customize as needed)
    return true if skip_authorization?(controller_name, action_name)
    
    # Check if user has super admin permissions
    return true if user_is_super_admin?

    # Check if user has a role with permission for this controller/action
    current_user.roles.joins(permission_assignments: :permission)
      .where(hub_admin_permissions: { controller: controller_name, action: action_name, status: 'active' })
      .exists?
  end

  def skip_authorization?(controller_name, action_name)
    # Add controllers/actions that should bypass authorization
    return true if controller_name == 'hub/home'
    return true if controller_name == 'sessions'
    return true if controller_name == 'passwords'
    # You can add more exemptions here
    
    false
  end

  def user_is_super_admin?
    # Check if user has the admin role
    current_user.roles.where(name: 'admin').exists?
  end
end
