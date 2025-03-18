# The NotificationsJob processes batch notifications in the background
# This job leverages Rails 8's Solid Queue for improved background processing
# and helps to prevent blocking the main thread when sending notifications to many users
class NotificationsJob < ApplicationJob
  queue_as :default

  # Process the notification job - supports both single and batch notifications
  # @overload perform(user_id:, notifications:)
  #   @param user_id [Integer] The user ID to create notifications for
  #   @param notifications [Array<Hash>] Array of notification hashes with :message, :type, and optional :data
  # @overload perform(users:, message:, notification_type:, metadata: {}, url: nil)
  #   @param users [Array<User>] The users to create notifications for
  #   @param message [String] The notification message
  #   @param notification_type [String] The type of notification (info, success, warning, error)
  #   @param metadata [Hash] Additional data to store with the notification
  #   @param url [String, nil] URL associated with the notification
  # @return [Array<Hub::Notification>] The created notifications
  def perform(user_id: nil, users: nil, notifications: nil, message: nil, notification_type: nil, metadata: {}, url: nil)
    # Handle multiple job formats - batch or individual notifications
    if user_id.present? && notifications.present?
      # Batch format: one user with multiple notifications
      process_batch_for_user(user_id, notifications)
    elsif users.present? && message.present? && notification_type.present?
      # Standard format: multiple users with same notification
      process_standard(users, message, notification_type, metadata, url)
    else
      # Invalid parameters
      Rails.logger.error("NotificationsJob called with invalid parameters")
      raise ArgumentError, "Must provide either (user_id, notifications) or (users, message, notification_type)"
    end
  end
  
  private
  
  # Process a batch of different notifications for a single user
  # @param user_id [Integer] The user ID to notify
  # @param notifications [Array<Hash>] Array of notification data
  def process_batch_for_user(user_id, notifications)
    # Find the user
    user = Hub::Admin::User.find_by(id: user_id)
    return unless user
    
    # Process each notification
    notifications.each do |notification_data|
      # Validate required fields
      next unless notification_data[:message].present? && notification_data[:notification_type].present?
      
      # Create notification
      Hub::NotificationService.notify(
        user: user,
        message: notification_data[:message],
        notification_type: notification_data[:notification_type],
        metadata: notification_data[:metadata] || {},
        url: notification_data[:url]
      )
    end
  end
  
  # Process the standard notification format (same notification to multiple users)
  # @param users [Array<User>] The users to create notifications for
  # @param message [String] The notification message
  # @param notification_type [String] The type of notification
  # @param metadata [Hash] Additional data to store with the notification
  # @param url [String, nil] URL associated with the notification
  def process_standard(users, message, notification_type, metadata, url)
    # Validate required parameters
    if message.blank? || notification_type.blank?
      Rails.logger.error("Required parameters missing in NotificationsJob#process_standard")
      return
    end
    
    # Set default values
    metadata ||= {}

    # Process each user in smaller batches for better performance
    Array(users).in_groups_of(50, false) do |user_batch|
      user_batch.each do |user|
        # Create notification without immediate broadcast to prevent overwhelming
        # the Solid Cable connections
        Hub::NotificationService.notify(
          user: user,
          message: message,
          notification_type: notification_type,
          metadata: metadata,
          url: url
        )
      end
      
      # Allow other jobs to process between batches
      sleep(0.1)
    end
  end
end
