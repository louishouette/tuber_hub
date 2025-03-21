# frozen_string_literal: true

class RolePolicy < ApplicationPolicy
  include PermissionPolicyConcern
  
  def index?
    user.admin? || permission_check
  end
  
  def show?
    user.admin? || permission_check
  end
  
  def create?
    user.admin? || permission_check
  end
  
  def update?
    user.admin? || permission_check
  end
  
  def destroy?
    user.admin?
  end
  
  def assign_permissions?
    user.admin? || permission_check(custom_action: 'assign_permissions')
  end
  
  def users?
    user.admin? || permission_check(custom_action: 'view_users')
  end
  
  class Scope < Scope
    def resolve
      if user.admin?
        scope.all
      else
        # Return roles that the user has permission to view
        namespace = 'hub/admin'
        controller = 'roles'
        action = 'index'
        
        if user.can?(action, namespace, controller)
          scope.all
        else
          scope.none
        end
      end
    end
  end
end
