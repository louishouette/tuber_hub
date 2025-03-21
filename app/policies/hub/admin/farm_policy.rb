module Hub
  module Admin
    class FarmPolicy < ApplicationPolicy
      include PermissionPolicyConcern

      def index?
        user.admin? || permission_check
      end

      def show?
        user.admin? || 
          user.farms.include?(record) || 
          permission_check
      end

      def create?
        user.admin? || permission_check
      end

      def update?
        user.admin? || permission_check
      end
      
      # Used for controlling who can add or remove farm members
      def edit?
        user.admin? || 
          user.farms.include?(record) || 
          permission_check(custom_action: 'update')
      end

      def destroy?
        user.admin? || permission_check
      end

      def set_current_farm?
        user.farms.include?(record) || user.admin?
      end

      class Scope < Scope
        def resolve
          if user.admin?
            scope.all
          else
            # Get only farms the user has access to
            user.farms
          end
        end
      end
    end
  end
end
