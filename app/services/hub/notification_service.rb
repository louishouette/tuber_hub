module Hub
  class NotificationService
    VALID_TYPES = %w[info success warning error].freeze
    
    def self.notify(user:, message:, notification_type: "info", metadata: {}, url: nil)
      notification_type = "info" unless VALID_TYPES.include?(notification_type.to_s)
      
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
    
    def self.mark_as_read(notification)
      notification.update!(read_at: Time.zone.now)
    end
    
    def self.dismiss(notification)
      notification.update!(dismissed_at: Time.zone.now)
    end
    
    def self.mark_as_displayed(notification)
      notification.update!(displayed_at: Time.zone.now)
    end
    
    private
    
    def self.broadcast_notification(notification)
      # Use the NotificationChannel to broadcast directly to the user
      Hub::NotificationChannel.broadcast_to(
        notification.user,
        {
          notification: {
            id: notification.id,
            message: notification.message,
            notification_type: notification.notification_type,
            created_at: notification.created_at,
            url: notification.url
          }
        }
      )
    end
    
    def self.notify_all(users:, message:, notification_type: "info", metadata: {}, url: nil)
      users.each do |user|
        notify(user: user, message: message, notification_type: notification_type, metadata: metadata, url: url)
      end
    end
    
    def self.notify_and_broadcast(user:, message:, notification_type: "info", metadata: {}, url: nil)
      # Create the notification first
      notification = notify(user: user, message: message, notification_type: notification_type, metadata: metadata, url: url)
      
      # Then broadcast it to the user via Action Cable
      broadcast_notification(notification)
      
      notification
    end
  end
end
