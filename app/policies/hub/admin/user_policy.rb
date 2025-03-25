# frozen_string_literal: true

module Hub
  module Admin
    class UserPolicy < ApplicationPolicy
      include PermissionPolicyConcern
      
      # Policy for Hub::Admin::User with role-based permissions
      def index?
        Current.user.admin? || permission_check
      end

      def show?
        Current.user.admin? || record == Current.user || permission_check
      end

      def create?
        Current.user.admin? || permission_check
      end

      def update?
        Current.user.admin? || record == Current.user || permission_check
      end

      def destroy?
        Current.user.admin? || permission_check
      end
      
      def assign_roles?
        Current.user.admin? || permission_check(custom_action: 'assign_roles')
      end
      
      def toggle_active?
        Current.user.admin? || permission_check(custom_action: 'toggle_active')
      end
      
      def by_role?
        Current.user.admin? || permission_check(custom_action: 'view_by_role')
      end

      class Scope < Scope
        def resolve
          if Current.user.admin?
            scope.all
          else
            namespace = 'hub/admin'
            controller = 'users'
            action = 'index'
            
            if Current.user.can?(action, namespace, controller)
              scope.all
            else
              scope.where(id: Current.user.id) # Users can only access their own records
            end
          end
        end
      end
    end
  end
end
