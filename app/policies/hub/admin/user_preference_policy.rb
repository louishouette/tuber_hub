# frozen_string_literal: true

module Hub
  module Admin
    # Policy for Hub::Admin::UserPreference resource
    class UserPreferencePolicy < BasePolicy
      def index?
        user_can?(:index, 'user_preferences', 'hub/admin')
      end

      def show?
        user_can?(:show, 'user_preferences', 'hub/admin') && user_owns_preference?
      end

      def create?
        user_can?(:create, 'user_preferences', 'hub/admin') && user_owns_preference?
      end

      def update?
        user_can?(:update, 'user_preferences', 'hub/admin') && user_owns_preference?
      end

      def destroy?
        user_can?(:destroy, 'user_preferences', 'hub/admin') && user_owns_preference?
      end
      
      def settings?
        user_can?(:index, 'user_preferences', 'hub/admin')
      end
      
      def update_preference?
        user_can?(:update, 'user_preferences', 'hub/admin')
      end
      
      def set_default_farm?
        user_can?(:update, 'user_preferences', 'hub/admin')
      end

      private

      # Ensure users can only manage their own preferences
      def user_owns_preference?
        record.user_id == Current.user&.id
      end

      class Scope < Scope
        def resolve
          if user_can?(:index, 'user_preferences', 'hub/admin')
            # Admin users can see all preferences
            if Current.user.admin?
              scope.all
            else
              # Regular users can only see their own preferences
              scope.where(user_id: Current.user.id)
            end
          else
            scope.none
          end
        end
      end
    end
  end
end
