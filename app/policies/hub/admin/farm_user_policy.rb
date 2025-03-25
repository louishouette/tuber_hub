module Hub
  module Admin
    class FarmUserPolicy < ApplicationPolicy
      include PermissionPolicyConcern
      
      def create?
        # Only users who can edit the farm can add members
        return true if Current.user.admin?
        farm = record.farm
        FarmPolicy.new(Current.user, farm).edit?
      end
      
      def destroy?
        # Only users who can edit the farm can remove members
        # But users should not be able to remove themselves
        return false if record.user == Current.user # User cannot remove themselves
        return true if Current.user.admin?
        farm = record.farm
        FarmPolicy.new(Current.user, farm).edit?
      end
      
      class Scope < Scope
        def resolve
          if Current.user.admin?
            scope.all
          else
            # Filter by farms the user has access to
            scope.joins(:farm).where(farm: Current.user.farms)
          end
        end
      end
    end
  end
end
