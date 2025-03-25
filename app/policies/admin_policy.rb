# frozen_string_literal: true

# This policy handles authorization for admin-specific controllers and actions
# It replaces the custom admin authorization logic in Hub::Admin::BaseController
module Hub
  # Policy for Hub::Admin namespace
  class AdminPolicy < ApplicationPolicy
    include PermissionPolicyConcern
  
  attr_reader :user, :record

  def initialize(user, record)
    @user = user || (defined?(Current) ? Current.user : nil)
    @record = record # Symbol or specific admin resource
  end

  # Standard CRUD action methods following Pundit conventions
  def index?
    Current.user&.admin?
  end

  def show?
    Current.user&.admin?
  end

  def create?
    Current.user&.admin?
  end

  def new?
    create?
  end

  def update?
    Current.user&.admin?
  end

  def edit?
    update?
  end

  def destroy?
    Current.user&.admin?
  end

  # Method to authorize viewing users for a role
  def users?
    Current.user&.admin?
  end

  # Legacy method for backward compatibility
  # @deprecated Use standard Pundit action methods instead (index?, show?, etc.)
  def access?
    Rails.logger.warn "[DEPRECATION] AdminPolicy#access? is deprecated. Use standard Pundit methods instead."
    Current.user&.admin?
  end
  
  # Method to authorize assigning roles to users
  def assign_roles?
    Current.user&.admin? || permission_check(custom_action: 'assign_roles')
  end
  
  # Method to authorize assigning permissions to roles
  def assign_permissions?
    Current.user&.admin? || permission_check(custom_action: 'assign_permissions')
  end
  
  # Method to authorize searching for resources
  def search?
    Current.user&.admin? || permission_check(custom_action: 'search')
  end
  
  # Method to authorize refreshing permissions
  def refresh?
    Current.user&.admin? || permission_check(custom_action: 'refresh')
  end
  
  private
  
  # Permission check method for admin actions
  # @param custom_action [String] optional custom action to check
  # @return [Boolean] whether the user has permission
  def permission_check(custom_action: nil)
    # Extract controller and action from the record if available, otherwise use defaults
    namespace = 'hub/admin'
    controller = record.is_a?(Symbol) ? record.to_s : 'admin'
    action = custom_action || caller_locations(1,1)[0].label.to_s.chomp('?')
    
    # Check permission through the authorization service
    AuthorizationService.user_has_permission?(Current.user, namespace, controller, action)
  end

  class Scope < Scope
    def resolve
      if Current.user&.admin?
        scope.all
      else
        scope.none
      end
    end
  end
end
