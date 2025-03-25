module Hub
  module Admin
    class PermissionPolicy < ApplicationPolicy
      include PermissionPolicyConcern
      
      def index?
        Current.user.admin? || permission_check
      end
      
      def show?
        Current.user.admin? || permission_check
      end
      
      def refresh?
        Current.user.admin? # Only admins can refresh permissions
      end
      
      class Scope < Scope
        def resolve
          if Current.user.admin?
            scope.all
          else
            scope.where(status: 'active')
          end
        end
      end
    end
  end
end
