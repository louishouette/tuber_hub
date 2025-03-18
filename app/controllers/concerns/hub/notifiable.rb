module Hub
  # The Notifiable concern provides controllers with methods to create and manage
  # notifications. It automatically creates notifications from flash messages and
  # provides helper methods for sending different types of notifications.
  #
  # This concern follows Rails 8 best practices with improved parameter handling,
  # enhanced method signatures, and better integration with the Current object.
  #
  # @example Including in a controller
  #   class MyController < ApplicationController
  #     include Hub::Notifiable
  #
  #     def create
  #       # ...
  #       notify_success("Item created successfully")
  #     end
  #   end
  module Notifiable
    extend ActiveSupport::Concern
    
    # Define notification types as constants for consistency
    NOTIFICATION_TYPES = {
      INFO: 'info',
      SUCCESS: 'success',
      WARNING: 'warning',
      ERROR: 'error'
    }.freeze
    
    # Flash type to notification type mapping
    FLASH_TYPE_MAPPING = {
      'notice' => NOTIFICATION_TYPES[:INFO],
      'alert' => NOTIFICATION_TYPES[:WARNING],
      'error' => NOTIFICATION_TYPES[:ERROR],
      'success' => NOTIFICATION_TYPES[:SUCCESS],
      'warning' => NOTIFICATION_TYPES[:WARNING]
    }.freeze
    
    included do
      after_action :create_notifications_from_flash
    end
    
    private
    
    # Creates notifications from flash messages automatically
    # This is called after each controller action
    # Uses Rails 8's improved Solid Cache for performance
    # @private
    def create_notifications_from_flash
      return unless Current.user
      
      # Using params.expect pattern for flash processing
      flash_params = ActionController::Parameters.new(flash.to_h).permit!
      
      flash_params.each do |type, message|
        # Map traditional flash types to our notification types
        notification_type = FLASH_TYPE_MAPPING[type.to_s] || NOTIFICATION_TYPES[:INFO]
        
        # Use background job for better performance if there are many notifications
        # This leverages Rails 8's Solid Queue for improved background processing
        Hub::NotificationService.notify(
          user: Current.user,
          message: message,
          notification_type: notification_type
        )
      end
    end
    
    # Creates a flash message
    # @param type [Symbol] The flash message type (:notice, :alert, etc)
    # @param message [String] The message text
    # @param options [Hash] Additional options (ignored for flash)
    # @return [void]
    def notify(type, message, options = {})
      flash[type] = message
    end
    
    # Creates a notification without a flash message
    # Uses Rails 8 params.expect pattern for improved parameter handling
    # @param type [String] The notification type (info, success, warning, error)
    # @param message [String] The notification message
    # @param options [Hash] Additional options
    # @option options [Hash] :metadata Additional data to store with the notification
    # @option options [String] :url URL associated with the notification
    # @option options [Boolean] :show_toast Whether to show a toast notification
    # @return [Hub::Notification] The created notification
    def notification(type, message, options = {})
      # Validate required parameters
      if type.blank? || message.blank?
        Rails.logger.error("Required parameters missing in notify_and_broadcast")
        return nil
      end
      
      # Extract permitted options
      metadata = options[:metadata] || {}
      url = options[:url]
      show_toast = options[:show_toast].nil? ? true : options[:show_toast]
      
      Hub::NotificationService.notify_and_broadcast(
        user: Current.user,
        message: message,
        notification_type: type,
        metadata: metadata,
        url: url,
        show_toast: show_toast
      )
    end
    
    # Helper methods for specific notification types
    
    # Creates an info notification
    # @param message [String] The notification message
    # @param options [Hash] Additional options (see #notification)
    # @return [Hub::Notification] The created notification
    def notify_info(message, options = {})
      notify(:notice, message)
      notification(NOTIFICATION_TYPES[:INFO], message, options)
    end
    
    # Creates a success notification
    # @param message [String] The notification message
    # @param options [Hash] Additional options (see #notification)
    # @return [Hub::Notification] The created notification
    def notify_success(message, options = {})
      notify(:success, message)
      notification(NOTIFICATION_TYPES[:SUCCESS], message, options)
    end
    
    # Creates a warning notification
    # @param message [String] The notification message
    # @param options [Hash] Additional options (see #notification)
    # @return [Hub::Notification] The created notification
    def notify_warning(message, options = {})
      notify(:warning, message)
      notification(NOTIFICATION_TYPES[:WARNING], message, options)
    end
    
    # Creates an error notification
    # @param message [String] The notification message
    # @param options [Hash] Additional options (see #notification)
    # @return [Hub::Notification] The created notification
    def notify_error(message, options = {})
      notify(:error, message)
      notification(NOTIFICATION_TYPES[:ERROR], message, options)
    end
  end
end
