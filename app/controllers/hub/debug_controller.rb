# frozen_string_literal: true

module Hub
  # Debug controller for testing features
  class DebugController < ApplicationController
    # Testing endpoint for notifications
    def test_notification
      # Create a notification
      notification = Notification.create!(
        user: current_user,
        message: "🧪 Test notification created at #{Time.zone.now.strftime('%H:%M:%S')}",
        notification_type: %w[info success warning error].sample,
        read_at: nil,
        url: ['/hub', '/hub/notifications', nil].sample
      )

      # Get the unread count for this user
      unread_count = Notification.unread.for_user(current_user.id).count

      # Create notification data to broadcast
      notification_data = {
        id: notification.id,
        message: notification.message,
        notification_type: notification.notification_type,
        created_at: notification.created_at,
        url: notification.url,
        unread_count: unread_count,
        show_toast: true
      }

      # Broadcast directly using ActionCable
      ActionCable.server.broadcast(
        "notifications_#{current_user.id}",
        { notification: notification_data }
      )

      # Return the notification data as JSON
      render json: { success: true, id: notification.id, notification: notification_data, unread_count: unread_count }
    end
  end
end
