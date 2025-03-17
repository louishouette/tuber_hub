module Hub
  # Policy for Hub::Notification model
  # Defines permissions for working with notifications
  class NotificationPolicy < ApplicationPolicy
    # Only the owner of a notification can see it
    def show?
      user_is_owner?
    end
    
    # Only administrators can create notifications for other users
    def create?
      user&.admin?
    end
    
    # Only the owner of a notification can update its status
    def update?
      user_is_owner?
    end
    
    # Alias for read, dismiss, displayed, etc.
    alias_method :read?, :update?
    alias_method :dismiss?, :update?
    alias_method :displayed?, :update?
    
    # Only the owner of a notification can destroy it
    def destroy?
      user_is_owner?
    end
    
    # Class for scoped collections of notifications
    class Scope < Scope
      # Users can only view their own notifications
      def resolve
        return scope.none unless user
        scope.where(user_id: user.id)
      end
    end
    
    private
    
    # Checks if the current user is the owner of the notification
    def user_is_owner?
      user && record.user_id == user.id
    end
  end
end
