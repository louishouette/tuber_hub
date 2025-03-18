# The NotificationCleanupJob handles automatic cleaning of notifications
# It performs two key functions:
# 1. Auto-mark notifications as read based on their type and age
# 2. Delete old notifications after 3 weeks
class NotificationCleanupJob < ApplicationJob
  queue_as :low_priority
  
  # Perform the cleanup operations
  # @return [Hash] Statistics about the cleanup operation
  def perform
    stats = {
      auto_read: mark_auto_expired_as_read,
      old_deleted: remove_old_notifications
    }
    
    # Log the results
    Rails.logger.info("NotificationCleanupJob completed: #{stats[:auto_read]} auto-read, #{stats[:old_deleted]} old deleted")
    
    stats
  end
  
  private
  
  # Mark notifications as read that have auto-expired based on their type and age
  # info/success: 1 minute
  # warning: 5 minutes
  # error: 1 hour
  # @return [Integer] Number of notifications marked as read
  def mark_auto_expired_as_read
    # Find all notifications that should be auto-marked as read
    expired_notifications = Hub::Notification.auto_expired
    count = expired_notifications.count
    
    # Mark them as read in bulk for better performance
    expired_notifications.update_all(read_at: Time.zone.now)
    
    # Broadcast updates for each affected user
    affected_users = Hub::Admin::User.joins(:notifications)
                                    .where(hub_notifications: { id: expired_notifications.select(:id) })
                                    .distinct
    
    affected_users.each do |user|
      unread_count = Hub::Notification.unread.for_user(user.id).count
      
      # Broadcast the updated count
      if defined?(Hub::NotificationChannel)
        Hub::NotificationChannel.broadcast_to(
          user,
          { type: 'count_update', count: unread_count, timestamp: Time.zone.now.to_i }
        )
      end
      
      # Invalidate cache
      Rails.cache.delete("user_#{user.id}_unread_count")
    end
    
    count
  end
  
  # Remove notifications older than 3 weeks
  # @return [Integer] Number of notifications deleted
  def remove_old_notifications
    cutoff_date = 3.weeks.ago
    old_notifications = Hub::Notification.where('created_at < ?', cutoff_date)
    count = old_notifications.count
    
    old_notifications.delete_all
    
    count
  end
end
