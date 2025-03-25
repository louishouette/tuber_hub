module Hub
  module Admin
    class FarmPolicy < ApplicationPolicy
      include PermissionPolicyConcern

      def index?
        Current.user.admin? || permission_check
      end

      def show?
        Current.user.admin? || 
          Current.user.farms.include?(record) || 
          permission_check
      end

      def create?
        Current.user.admin? || permission_check
      end

      def update?
        Current.user.admin? || permission_check
      end
      
      # Used for controlling who can add or remove farm members
      def edit?
        Current.user.admin? || 
          Current.user.farms.include?(record) || 
          permission_check(custom_action: 'update')
      end

      def destroy?
        Current.user.admin? || permission_check
      end

      def set_current_farm?
        Current.user.farms.include?(record) || Current.user.admin?
      end

      class Scope < Scope
        def resolve
          if Current.user.admin?
            scope.all
          else
            # Get only farms the user has access to
            Current.user.farms
          end
        end
      end
    end
  end
end
