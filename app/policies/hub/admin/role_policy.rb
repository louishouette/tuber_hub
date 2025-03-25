# frozen_string_literal: true

module Hub
  module Admin
    class RolePolicy < ApplicationPolicy
      include PermissionPolicyConcern
      
      def index?
        Current.user.admin? || permission_check
      end
      
      def show?
        Current.user.admin? || permission_check
      end
      
      def create?
        Current.user.admin? || permission_check
      end
      
      def update?
        Current.user.admin? || permission_check
      end
      
      def destroy?
        Current.user.admin?
      end
      
      def assign_permissions?
        Current.user.admin? || permission_check(custom_action: 'assign_permissions')
      end
      
      def users?
        Current.user.admin? || permission_check(custom_action: 'view_users')
      end
      
      class Scope < Scope
        def resolve
          if Current.user.admin?
            scope.all
          else
            # Return roles that the user has permission to view
            namespace = 'hub/admin'
            controller = 'roles'
            action = 'index'
            
            if Current.user.can?(action, namespace, controller)
              scope.all
            else
              scope.none
            end
          end
        end
      end
    end
  end
end
