# frozen_string_literal: true

module Hub
  # Policy for Hub::Cultivation namespace
  class CultivationPolicy < ApplicationPolicy
    def index?
      # Any authenticated user can access Cultivation namespace
      Current.user.present?
    end

    def show?
      Current.user.present? && user_has_farm_access?
    end

    def create?
      Current.user.present? && user_has_farm_access?
    end

    def update?
      Current.user.present? && user_has_farm_access?
    end

    def destroy?
      Current.user.present? && user_has_farm_access?
    end

    private

    def user_has_farm_access?
      # Use Current.farm as the source of truth for the current farm
      return false unless Current.farm.present?
      
      # Check if the user has access to this farm
      Current.user.farms.exists?(id: Current.farm.id)
    end

    class Scope < Scope
      def resolve
        if Current.user.present?
          if Current.farm.present? && Current.user.farms.exists?(id: Current.farm.id)
            # If Current.farm is set and user has access, scope to that farm
            scope.where(farm_id: Current.farm.id)
          else
            # Otherwise, scope to all farms the user has access to
            scope.where(farm_id: Current.user.farms.pluck(:id))
          end
        else
          scope.none
        end
      end
    end
  end
end
