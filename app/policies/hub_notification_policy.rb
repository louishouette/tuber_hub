# frozen_string_literal: true

# Policy for Hub::Notification model using the non-namespaced policy class name
# This is just a redirect to the actual policy in the proper namespace
class HubNotificationPolicy < ApplicationPolicy
  # Delegate all permission checks to Hub::NotificationPolicy
  def method_missing(method_name, *args, &block)
    if method_name.to_s.end_with?('?')
      # Create a new instance of Hub::NotificationPolicy and forward the method call
      Hub::NotificationPolicy.new(user, record).send(method_name, *args, &block)
    else
      super
    end
  end

  def respond_to_missing?(method_name, include_private = false)
    method_name.to_s.end_with?('?') || super
  end

  # Class for scoped collections of notifications
  class Scope < Scope
    def resolve
      Hub::NotificationPolicy::Scope.new(user, scope).resolve
    end
  end
end
