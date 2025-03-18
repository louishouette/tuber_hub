module Hub
  # Service object for creating and broadcasting notifications
  # This service handles the creation, broadcasting, and management of notifications
  # and provides both instance methods for use with a specific user and class methods
  # for use with any user.
  #
  # @example Creating a notification for a specific user
  #   # Instance method approach
  #   service = Hub::NotificationService.new(Current.user)
  #   service.notify(message: 'Hello!', notification_type: 'info')
  #
  #   # Class method approach
  #   Hub::NotificationService.notify(user: Current.user, message: 'Hello!', notification_type: 'info')
  #
  # This service utilizes Rails 8 features:
  # - Solid Cache for performance optimization
  # - Solid Queue for background processing when needed
  # - Modern parameter validation patterns
  class NotificationService
    include ActiveSupport::Configurable
    # Rails 8 includes parameter validation in ActionController::Parameters directly
    
    # Re-use the constants from the Notifiable concern for consistency
    NOTIFICATION_TYPES = Hub::Notifiable::NOTIFICATION_TYPES
    VALID_TYPES = NOTIFICATION_TYPES.values.freeze
    
    attr_reader :user
    
    def initialize(user)
      @user = user
    end
    
    # Instance methods for use with a specific user
    
    # Creates a notification for the initialized user
    # @param message [String] The notification message
    # @param notification_type [String] The type of notification (info, success, warning, error)
    # @param metadata [Hash] Additional data to store with the notification
    # @param url [String, nil] URL associated with the notification
    # @return [Hub::Notification] The created notification
    def notify(message:, notification_type: NOTIFICATION_TYPES[:INFO], metadata: {}, url: nil)
      self.class.notify(
        user: @user, 
        message: message, 
        notification_type: notification_type, 
        metadata: metadata, 
        url: url
      )
    end
    
    # Creates a notification for the initialized user and broadcasts it via Action Cable
    # @param message [String] The notification message
    # @param notification_type [String] The type of notification (info, success, warning, error)
    # @param metadata [Hash] Additional data to store with the notification
    # @param url [String, nil] URL associated with the notification
    # @param show_toast [Boolean] Whether to show a toast notification
    # @return [Hub::Notification] The created notification
    def notify_and_broadcast(message:, notification_type: NOTIFICATION_TYPES[:INFO], metadata: {}, url: nil, show_toast: true)
      notification = notify(
        message: message, 
        notification_type: notification_type, 
        metadata: metadata, 
        url: url
      )
      
      self.class.broadcast_notification(notification, show_toast: show_toast)
      notification
    end
    
    # Class methods for use with any user
    
    # Creates a notification for the specified user
    # @param user [User] The user to create the notification for
    # @param message [String] The notification message
    # @param notification_type [String] The type of notification (info, success, warning, error)
    # @param metadata [Hash] Additional data to store with the notification
    # @param url [String, nil] URL associated with the notification
    # @return [Hub::Notification] The created notification
    def self.notify(user:, message:, notification_type: NOTIFICATION_TYPES[:INFO], metadata: {}, url: nil)
      # Validate required parameters
      if message.blank? || notification_type.blank?
        raise ArgumentError, "message and notification_type are required"
      end
      
      # Set default values
      metadata ||= {}
      
      # Validate the notification type
      notification_type = NOTIFICATION_TYPES[:INFO] unless VALID_TYPES.include?(notification_type.to_s)
      
      notification = Hub::Notification.create!(
        user: user,
        message: message,
        notification_type: notification_type,
        metadata: metadata,
        url: url
      )
      
      # Broadcasting the notification via Solid Cable
      broadcast_notification(notification)
      
      notification
    end
    
    # Marks a notification as read
    # @param notification [Hub::Notification] The notification to mark as read
    # @return [Boolean] Whether the update was successful
    def self.mark_as_read(notification)
      notification.update!(read_at: Time.zone.now)
    end
    
    # Marks a notification as dismissed
    # @param notification [Hub::Notification] The notification to dismiss
    # @return [Boolean] Whether the update was successful
    def self.dismiss(notification)
      notification.update!(dismissed_at: Time.zone.now)
    end
    
    # Marks a notification as displayed
    # @param notification [Hub::Notification] The notification to mark as displayed
    # @return [Boolean] Whether the update was successful
    def self.mark_as_displayed(notification)
      notification.update!(displayed_at: Time.zone.now)
    end
    
    private
    
    # Broadcasts a notification to the user via Action Cable
    # @param notification [Hub::Notification] The notification to broadcast
    # @param show_toast [Boolean] Whether to show a toast notification
    # @return [void]
    def self.broadcast_notification(notification, show_toast: true)
      # Get the current unread count for the user using Solid Cache for better performance
      # This is a Rails 8 feature for improved caching
      unread_count = Rails.cache.fetch("user_#{notification.user_id}_unread_count", expires_in: 5.minutes) do
        Hub::Notification.where(user: notification.user).unread.count
      end
      
      # Use the NotificationChannel to broadcast directly to the user via Solid Cable
      Hub::NotificationChannel.broadcast_to(
        notification.user,
        {
          notification: {
            id: notification.id,
            message: notification.message,
            notification_type: notification.notification_type,
            created_at: notification.created_at,
            url: notification.url,
            show_toast: show_toast,
            unread_count: unread_count
          }
        }
      )
    end
    
    # Creates notifications for multiple users
    # Using Rails 8's improved Solid Queue for processing when there are many users
    # @param users [Array<User>] The users to create notifications for
    # @param message [String] The notification message
    # @param notification_type [String] The type of notification (info, success, warning, error)
    # @param metadata [Hash] Additional data to store with the notification
    # @param url [String, nil] URL associated with the notification
    # @param use_background_job [Boolean] Whether to use a background job (recommended for large user groups)
    # @return [Array<Hub::Notification>] The created notifications or job id if backgrounded
    def self.notify_all(users:, message:, notification_type: NOTIFICATION_TYPES[:INFO], metadata: {}, url: nil, use_background_job: false)
      return NotificationsJob.perform_later(users: users, message: message, notification_type: notification_type, metadata: metadata, url: url) if use_background_job && users.size > 10
      
      users.map do |user|
        notify(user: user, message: message, notification_type: notification_type, metadata: metadata, url: url)
      end
    end
    
    # Creates a notification for the specified user and broadcasts it via Action Cable
    # @param user [User] The user to create the notification for
    # @param message [String] The notification message
    # @param notification_type [String] The type of notification (info, success, warning, error)
    # @param metadata [Hash] Additional data to store with the notification
    # @param url [String, nil] URL associated with the notification
    # @param show_toast [Boolean] Whether to show a toast notification
    # @return [Hub::Notification] The created notification
    def self.notify_and_broadcast(user:, message:, notification_type: NOTIFICATION_TYPES[:INFO], metadata: {}, url: nil, show_toast: true)
      # Create the notification first
      notification = notify(user: user, message: message, notification_type: notification_type, metadata: metadata, url: url)
      
      # Then broadcast it to the user via Action Cable
      broadcast_notification(notification, show_toast: show_toast)
      
      notification
    end
  end
end
