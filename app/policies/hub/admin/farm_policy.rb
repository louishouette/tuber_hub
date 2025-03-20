module Hub
  module Admin
    class FarmPolicy < ApplicationPolicy
      def index?
        user.can?('index', 'hub/admin', 'farms') || user.admin?
      end

      def show?
        user.can?('show', 'hub/admin', 'farms') || 
          user.farms.include?(record) || 
          user.admin?
      end

      def create?
        user.can?('create', 'hub/admin', 'farms') || user.admin?
      end

      def update?
        user.can?('update', 'hub/admin', 'farms') || user.admin?
      end
      
      # Used for controlling who can add or remove farm members
      def edit?
        user.can?('update', 'hub/admin', 'farms') || 
          user.farms.include?(record) || 
          user.admin?
      end

      def destroy?
        user.can?('destroy', 'hub/admin', 'farms') || user.admin?
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
