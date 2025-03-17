module Hub
  module Notifiable
    extend ActiveSupport::Concern
    
    included do
      after_action :create_notifications_from_flash
    end
    
    private
    
    def create_notifications_from_flash
      return unless Current.user
      
      flash.each do |type, message|
        # Map traditional flash types to our notification types
        notification_type = case type.to_s
                            when 'notice' then 'info'
                            when 'alert' then 'warning'
                            when 'error', 'success', 'warning' then type.to_s
                            else 'info'
                            end
        
        Hub::NotificationService.notify(
          user: Current.user,
          message: message,
          notification_type: notification_type
        )
      end
    end
    
    # Enhanced flash methods that also generate notifications
    def notify(type, message, options = {})
      flash[type] = message
    end
    
    # Create a notification without a flash message
    def notification(type, message, options = {})
      Hub::NotificationService.notify(
        user: Current.user,
        message: message,
        notification_type: type,
        metadata: options[:metadata] || {},
        url: options[:url]
      )
    end
    
    # Helper methods for specific notification types
    def notify_info(message, options = {})
      notify(:notice, message)
      notification('info', message, options)
    end
    
    def notify_success(message, options = {})
      notify(:success, message)
      notification('success', message, options)
    end
    
    def notify_warning(message, options = {})
      notify(:warning, message)
      notification('warning', message, options)
    end
    
    def notify_error(message, options = {})
      notify(:error, message)
      notification('error', message, options)
    end
  end
end
