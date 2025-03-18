namespace :notifications do
  desc "Generate test notifications for development"
  task :generate_test => :environment do
    puts "Generating test notifications..."
    
    # Create a few test users if none exist
    unless Hub::Admin::User.exists?
      puts "Error: No users found. Please create at least one user first."
      exit 1
    end
    
    # Get a random subset of users to create notifications for
    users = Hub::Admin::User.order("RANDOM()").limit(3)
    
    # Define different types of test notifications with sample content
    notification_types = ['info', 'success', 'warning', 'error']
    
    sample_messages = [
      "Your potato has been harvested successfully!",
      "Someone commented on your potato post",
      "Your account subscription will expire soon",
      "There was a problem with your last transaction",
      "New feature: Potato ratings are now available!",
      "A new variety of potatoes has been added to the catalog",
      "Welcome to TuberHub! Get started by exploring potato varieties.",
      "System maintenance scheduled for tomorrow at 3 AM UTC"
    ]
    
    # Create notifications for each user
    users.each do |user|
      puts "Creating notifications for user: #{user.email_address} (#{user.full_name})"
      
      # Create one of each notification type
      notification_types.each do |type|
        message = sample_messages.sample
        
        # Create notification with Hub::NotificationService
        Hub::NotificationService.notify(
          user: user,
          message: message,
          notification_type: type,
          metadata: { 
            test: true,
            generated_at: Time.zone.now.iso8601
          }
        )
        
        puts "  Created #{type} notification: #{message}"
      end
      
      # Also batch a few notifications to test the background job
      batch_messages = sample_messages.sample(3)
      
      puts "  Queueing batch of #{batch_messages.size} notifications through background job"
      
      # Create batch notifications using NotificationsJob
      NotificationsJob.perform_later(
        user_id: user.id,
        notifications: batch_messages.map.with_index do |msg, i|
          {
            message: msg,
            notification_type: notification_types[i % notification_types.size],
            metadata: { batch: true, index: i }
          }
        end
      )
    end
    
    puts "Completed! Created notifications for #{users.size} users."
  end
  
  desc "Clear all notifications (development only)"
  task :clear_all => :environment do
    if Rails.env.production?
      puts "This task cannot be run in production!"
      exit 1
    end
    
    count = Hub::Notification.count
    Hub::Notification.delete_all
    puts "Deleted #{count} notifications."
  end
end
