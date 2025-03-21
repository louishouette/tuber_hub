# frozen_string_literal: true

class UserPolicy < ApplicationPolicy
  include PermissionPolicyConcern
  
  # Policy for Hub::Admin::User with role-based permissions
  def index?
    user.admin? || permission_check
  end

  def show?
    user.admin? || record == user || permission_check
  end

  def create?
    user.admin? || permission_check
  end

  def update?
    user.admin? || record == user || permission_check
  end

  def destroy?
    user.admin? || permission_check
  end
  
  def assign_roles?
    user.admin? || permission_check(custom_action: 'assign_roles')
  end
  
  def toggle_active?
    user.admin? || permission_check(custom_action: 'toggle_active')
  end
  
  def by_role?
    user.admin? || permission_check(custom_action: 'view_by_role')
  end

  class Scope < Scope
    def resolve
      if user.admin?
        scope.all
      else
        namespace = 'hub/admin'
        controller = 'users'
        action = 'index'
        
        if user.can?(action, namespace, controller)
          scope.all
        else
          scope.where(id: user.id) # Users can only access their own records
        end
      end
    end
  end
end
