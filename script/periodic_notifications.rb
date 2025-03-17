#!/usr/bin/env ruby
# frozen_string_literal: true

# This script generates test notifications every few seconds
# Usage: rails runner script/periodic_notifications.rb [count] [interval_seconds]

require File.expand_path('../config/environment', __dir__)

count = (ARGV[0] || 10).to_i
interval = (ARGV[1] || 5).to_i.seconds

notification_types = %w[info success warning error]
user = Current.user || Hub::Admin::User.first

if user.nil?
  puts "No user found. Please log in first or create a user."
  exit 1
end

puts "Generating #{count} notifications for user ID: #{user.id} with #{interval} seconds interval"
puts "Press Ctrl+C to stop"

messages = [
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
  begin
    message = messages.sample
    type = notification_types.sample
    url = ["/hub", "/hub/notifications", "/hub/admin/dashboard", nil, nil].sample # some with URLs, some without
    
    notification = Hub::NotificationService.notify_and_broadcast(
      user: user,
      message: message,
      notification_type: type,
      url: url
    )
    
    puts "[#{Time.current}] Created #{type} notification: #{message}"
    
    if i < count - 1
      # Sleep for the interval unless it's the last notification
      sleep interval
    end
  rescue StandardError => e
    puts "Error creating notification: #{e.message}"
  end
end

puts "Finished generating notifications"
