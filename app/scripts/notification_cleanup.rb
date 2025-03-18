#!/usr/bin/env ruby
# This script runs the notification cleanup job
# It's designed to be scheduled via cron or a similar scheduler

require_relative '../../config/environment'

# Run the notification cleanup job
result = NotificationCleanupJob.perform_now

# Output the results
puts "Notification cleanup completed at #{Time.zone.now}"
puts "Auto-read notifications: #{result[:auto_read]}"
puts "Old notifications deleted: #{result[:old_deleted]}"
