module Hub
  module Admin
    class PermissionPolicy < ApplicationPolicy
      include PermissionIntegration
      
      def index?
        user.admin? || permission_check
      end
      
      def show?
        user.admin? || permission_check
      end
      
      class Scope < Scope
        def resolve
          if user.admin?
            scope.all
          else
            scope.where(status: 'active')
          end
        end
      end
    end
  end
end
