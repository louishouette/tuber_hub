#!/usr/bin/env ruby
# frozen_string_literal: true

# This script generates test notifications for the current user
# Usage: rails runner script/generate_test_notifications.rb [count]

require File.expand_path('../config/environment', __dir__)

count = ARGV[0]&.to_i || 5
notification_types = %w[info success warning error]
user = Current.user || Hub::Admin::User.first

if user.nil?
  puts "No user found. Please log in first or create a user."
  exit 1
end

putting_types = [
  "A new #{rand(100..999)} kg harvest has been recorded",
  "Production #{rand(10..99)} reached critical stage",
  "Rain forecasted for Farm #{rand(1..10)} tomorrow",
  "New inspection scheduled for #{Date.today + rand(1..30).days}",
  "Temperature anomaly detected in Sector #{rand(1..20)}",
  "New task assigned to you by #{['John', 'Sarah', 'Mike', 'Emma', 'David'].sample}",
  "New comment on your harvest report",
  "System update completed successfully",
  "Backup completed for all farm data",
  "Payment confirmed for invoice ##{rand(1000..9999)}"
]

count.times do |i|
  message = putting_types.sample
  type = notification_types.sample
  url = ["/hub", "/hub/notifications", "/hub/core/farms", nil, nil].sample # some notifications with URLs, some without
  
  puts "\nBroadcasting notification to user ##{user.id}..."
  
  # Use the notification service to create and broadcast
  notification = Hub::NotificationService.notify_and_broadcast(
    user: user,
    message: message,
    notification_type: type,
    url: url
  )
  
  puts "  ✅ Notification ##{notification.id} created and broadcast attempted"
  puts "  📭 Notification type: #{type}"
  puts "  📃 Message: #{message}"
  puts "  🔗 URL: #{url || 'None'}"
  
  puts "Created #{type} notification: #{message}"
end

puts "\nCreated #{count} test notifications for user ID: #{user.id}"
puts "View them at http://localhost:3000/hub/notifications"
