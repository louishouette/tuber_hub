# frozen_string_literal: true

module Hub
  module Admin
    # This is just a redirect policy that points to the Hub::NotificationPolicy
    # It's needed due to how Pundit resolves policy classes
    class NotificationPolicy < ApplicationPolicy
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
  end
end
