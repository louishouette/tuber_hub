#!/usr/bin/env ruby
# frozen_string_literal: true

# Script to fix admin role assignments
# Fixes the case sensitivity issue with the admin role
# and ensures all users with the Admin role are properly assigned

puts "Starting admin role fix script..."

# Get the admin role - using case-insensitive query
admin_role = Hub::Admin::Role.where("LOWER(name) = ?", "admin").first

puts "Found admin role: #{admin_role&.name} (ID: #{admin_role&.id})"

if admin_role.nil?
  puts "Error: No admin role found in the database!"
  exit 1
end

# Make sure the role is consistently named 'admin' (lowercase)
if admin_role.name != 'admin'
  old_name = admin_role.name
  admin_role.update!(name: 'admin')
  puts "Updated role name from '#{old_name}' to 'admin' for consistency"
end

# Find all users with admin role assignments
admin_users = Hub::Admin::User.joins(:roles).where("LOWER(hub_admin_roles.name) = ?", "admin")

puts "Found #{admin_users.count} users with admin role"

# Current logged in user
current_user = Hub::Admin::User.find(Current.user.id) if Current.user
puts "Current user: #{current_user&.email_address}"

# If current user doesn't have admin role, assign it
if current_user && !current_user.admin?
  puts "Current user doesn't have admin role, assigning it now..."
  
  # Create a role assignment if one doesn't exist
  unless current_user.role_assignments.exists?(role: admin_role)
    current_user.role_assignments.create!(role: admin_role)
    puts "Assigned admin role to current user"
  end
end

puts "Script completed successfully!"
