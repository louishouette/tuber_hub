#!/usr/bin/env ruby
# frozen_string_literal: true

# This script tests direct ActionCable broadcasting
# Usage: rails runner script/debug_notifications.rb

require File.expand_path('../config/environment', __dir__)

user = Current.user || Hub::Admin::User.first

if user.nil?
  puts "No user found. Please log in first or create a user."
  exit 1
end

puts "\n🔌 Testing direct ActionCable broadcast..."

# Create a special debug notification that bypasses the service
debug_notification = Hub::Notification.create!(
  user: user,
  message: "⚡ DEBUG: This is a direct ActionCable test at #{Time.zone.now.strftime('%H:%M:%S')}.",
  notification_type: 'info',
  read_at: nil
)

puts "  ✅ Debug notification ##{debug_notification.id} created"

# Get the unread count for this user
unread_count = Hub::Notification.unread.for_user(user.id).count
puts "  📊 Current unread count: #{unread_count}"

# Try to broadcast directly using ActionCable
begin
  # Create notification data to broadcast
  notification_data = {
    id: debug_notification.id,
    message: debug_notification.message,
    notification_type: debug_notification.notification_type,
    created_at: debug_notification.created_at,
    unread_count: unread_count,
    show_toast: true
  }
  
  # Broadcast directly using ActionCable
  ActionCable.server.broadcast(
    "notifications_#{user.id}",
    { notification: notification_data }
  )
  
  puts "  ✅ Directly broadcasted via ActionCable to notifications_#{user.id} channel"
rescue => e
  puts "  ❌ Error broadcasting: #{e.message}"
  puts e.backtrace[0..3]
end

puts "\n✨ Done! Check your browser to see if notifications appear.\n"
