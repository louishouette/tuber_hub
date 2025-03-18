module Hub
  # The NotificationChannel handles real-time notification delivery via Solid Cable
  # This channel streams notifications directly to the user's browser and
  # handles user-initiated actions like marking notifications as read or dismissed.
  #
  # The channel is used by the NotificationService to broadcast notifications
  # and by the JavaScript client to receive and manage notifications.
  #
  # Rails 8 Solid Cable features used:
  # - Stream for specific records (stream_for)
  # - Built-in presence tracking
  # - Enhanced security with channel subscriptions
  class NotificationChannel < ApplicationCable::Channel
    include ActionCable::Channel::Streams
    include ActionCable::Channel::Broadcasting
    
    # Declares expected params for channel subscription
    # This is a new security feature in Rails 8
    # Use params.permit or verify configuration in connection setup instead
    
    # Subscribes the current user to their personal notification stream
    # @return [void]
    def subscribed
      # Log connection state for debugging
      Rails.logger.debug { "NotificationChannel#subscribed - Connection User: #{connection.current_user&.id}, Current.user: #{Current.user&.id}" }
      
      # Get user from either Current.user or connection.current_user
      user = Current.user || connection.current_user
      
      # Ensure we have a current user
      return reject_connection("No authenticated user") unless user
      
      # Stream directly for the user - use either Current.user or connection.current_user
      stream_for user
      
      # Track user presence for potential future features
      appear
      
      # Keep track of subscription time for analytics or rate limiting
      @subscribed_at = Time.zone.now
    end

      # Handles cleanup when the channel is unsubscribed
    # @return [void]
    def unsubscribed
      # Notify presence system the user has gone away
      disappear
      
      # Log disconnect time for analytics if needed
      # Get user from either Current.user or connection.current_user
      user = Current.user || connection.current_user
      if @subscribed_at && user
        Rails.logger.debug { "User #{user.id} disconnected from NotificationChannel after #{Time.zone.now - @subscribed_at} seconds" }
      end
    end
    
    # Track when a user appears (connects)
    # @return [void]
    def appear
      # Get user from either Current.user or connection.current_user
      user = Current.user || connection.current_user
      return unless user # Skip if no user
      
      ActionCable.server.broadcast("presence", { user_id: user.id, event: "online" })
    end
    
    # Track when a user disappears (disconnects)
    # @return [void]
    def disappear
      # Get user from either Current.user or connection.current_user
      user = Current.user || connection.current_user
      return unless user # Skip if no user
      
      ActionCable.server.broadcast("presence", { user_id: user.id, event: "offline" })
    end
    
    # Respond to pings to keep connection alive
    # @return [void]
    def pong
      # Simply respond to client pings to maintain connection health
    end
    
    # Marks a notification as read
    # @param data [Hash] Parameters containing the notification id
    # @option data [String] :id The ID of the notification to mark as read
    # @return [void]
    def mark_as_read(data)
      notification = find_notification(data['id'])
      return reject_unauthorized_action unless notification && can_modify_notification?(notification)
      
      # Use transaction for data consistency
      ActiveRecord::Base.transaction do
        notification.mark_as_read!
        
        # Record when the notification was read for analytics
        notification.update(read_at: Time.zone.now) unless notification.read_at
      end
      
      # Acknowledge successful action to the client
      transmit({ status: "success", action: "mark_as_read", id: notification.id })
      
      # Broadcast the updated unread count to keep all clients in sync
      broadcast_unread_count
    end
    
    # Dismisses a notification
    # @param data [Hash] Parameters containing the notification id
    # @option data [String] :id The ID of the notification to dismiss
    # @return [void]
    def dismiss(data)
      notification = find_notification(data['id'])
      return unless notification && can_modify_notification?(notification)
      
      notification.dismiss!
      
      # Broadcast the updated unread count and dismissal event to keep all clients in sync
      broadcast_to(current_user, { 
        type: 'notification_dismissed', 
        id: notification.id,
        timestamp: Time.zone.now.to_i
      })
      broadcast_unread_count
    end
    
    # Marks a notification as displayed
    # @param data [Hash] Parameters containing the notification id
    # @option data [String] :id The ID of the notification to mark as displayed
    # @return [void]
    def mark_as_displayed(data)
      notification = find_notification(data['id'])
      return unless notification && can_modify_notification?(notification)
      
      notification.mark_as_displayed!
    end
    
    # Request the current unread count from the server
    # This method can be called from the client to get updated counts
    # @return [void]
    def request_count
      # Just call the broadcast_unread_count method to send the current count to the client
      broadcast_unread_count
    end
    
    private
    
    # Finds a notification by ID with enhanced error handling
    # @param id [String] The ID of the notification to find
    # @return [Hub::Notification, nil] The notification if found, nil otherwise
    def find_notification(id)
      Hub::Notification.find_by(id: id)
    rescue ActiveRecord::RecordNotFound
      # Get user ID from either source
      user_id = Current.user&.id || connection.current_user&.id || 'unknown'
      Rails.logger.warn { "User #{user_id} attempted to access non-existent notification: #{id}" }
      nil
    end
    
    # Checks if the current user can modify the notification
    # @param notification [Hub::Notification] The notification to check
    # @return [Boolean] True if the user can modify the notification, false otherwise
    def can_modify_notification?(notification)
      # Get user from either Current.user or connection.current_user
      user = Current.user || connection.current_user
      user && notification.user_id == user.id
    end
    
    # Handles unauthorized actions gracefully
    # @return [void]
    def reject_unauthorized_action
      transmit({ status: "error", message: "Unauthorized action" })
    end
    
    # Rejects the connection with an error message
    # @param message [String] The error message to send
    # @return [void]
    def reject_connection(message)
      # Log the rejection for monitoring
      Rails.logger.warn { "Rejecting NotificationChannel connection: #{message}" }
      
      # Send a rejection message to the client
      transmit({ status: "error", message: message })
      
      # Return false to prevent subscription
      false
    end
    
    # Broadcasts the current user's unread notification count
    # @return [void]
    def broadcast_unread_count
      # Get user from either Current.user or connection.current_user
      user = Current.user || connection.current_user
      # Ensure we have a user
      return unless user
      
      # Use Solid Cache for better performance on counting queries
      # This leverages Rails 8's improved caching capabilities
      unread_count = Rails.cache.fetch("user_#{user.id}_unread_count", expires_in: 5.minutes) do
        Hub::Notification.where(user: user).unread.count
      end
      
      # Broadcast to the specific user's channel with just the unread count
      broadcast_to(user, { 
        type: 'unread_count_updated', 
        count: unread_count,
        timestamp: Time.zone.now.to_i
      })
    end
  end
end
