require_relative "../config/environment"

# This script runs the NotificationCleanupJob to handle:
# 1. Auto-marking notifications as read based on their type and age:
#    - info/success: after 1 minute
#    - warning: after 5 minutes
#    - error: after 1 hour
# 2. Removing notifications older than 3 weeks

puts "Starting notification cleanup at #{Time.zone.now}..."
result = NotificationCleanupJob.perform_now

# Output the results
puts "Notification cleanup completed!"
puts "Auto-marked as read: #{result[:auto_read]}"
puts "Removed old notifications: #{result[:old_deleted]}"
