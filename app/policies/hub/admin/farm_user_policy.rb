module Hub
  module Admin
    class FarmUserPolicy < ApplicationPolicy
      def create?
        # Only users who can edit the farm can add members
        farm = record.farm
        FarmPolicy.new(user, farm).edit?
      end
      
      def destroy?
        # Only users who can edit the farm can remove members
        # But users should not be able to remove themselves
        farm = record.farm
        return false if record.user == user # User cannot remove themselves
        FarmPolicy.new(user, farm).edit?
      end
    end
  end
end
