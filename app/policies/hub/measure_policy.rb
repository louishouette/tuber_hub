# frozen_string_literal: true

module Hub
  # Policy for Hub::Measure namespace
  class MeasurePolicy < ApplicationPolicy
    def index?
      # Any authenticated user can access Measure namespace
      user.present?
    end

    def show?
      user.present? && user_has_farm_access?
    end

    def create?
      user.present? && user_has_farm_access?
    end

    def update?
      user.present? && user_has_farm_access?
    end

    def destroy?
      user.present? && user_has_farm_access?
    end

    private

    def user_has_farm_access?
      # Use Current.farm as the source of truth for the current farm
      return false unless Current.farm.present?
      
      # Check if the user has access to this farm
      user.farms.exists?(id: Current.farm.id)
    end

    class Scope < Scope
      def resolve
        if user.present?
          if Current.farm.present? && user.farms.exists?(id: Current.farm.id)
            # If Current.farm is set and user has access, scope to that farm
            scope.where(farm_id: Current.farm.id)
          else
            # Otherwise, scope to all farms the user has access to
            scope.where(farm_id: user.farms.pluck(:id))
          end
        else
          scope.none
        end
      end
    end
  end
end
