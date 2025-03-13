#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative '../config/environment'

# Script to ensure the Admin role has all permissions in the system
# Run with: bin/rails runner script/ensure_admin_role_permissions.rb

puts "Starting admin role permissions script..."

# Find or create the admin role
admin_role = Hub::Admin::Role.find_or_create_by!(name: 'admin') do |role|
  role.description = 'Administrator with full system access'
  puts "Created new admin role"
end

puts "Using admin role: #{admin_role.name} (ID: #{admin_role.id})"

# Get all permissions
permissions = Hub::Admin::Permission.all
puts "Found #{permissions.count} total permissions in the system"

# Get existing permission assignments for the admin role
existing_assignments = admin_role.permission_assignments
puts "Admin role currently has #{existing_assignments.count} permission assignments"

# Identify permissions that need to be assigned
permission_ids_to_assign = permissions.pluck(:id) - existing_assignments.pluck(:permission_id)

# Find a system user to be the grantor
system_user = Hub::Admin::User.find_by(email_address: 'admin@example.com') || Hub::Admin::User.first

if system_user.nil?
  puts "Error: No user found to serve as the permission grantor"
  exit 1
end

puts "Using user #{system_user.email_address} as permission grantor"

# Create new permission assignments
permission_ids_to_assign.each do |permission_id|
  permission = Hub::Admin::Permission.find(permission_id)
  
  admin_role.permission_assignments.create!(
    permission_id: permission_id,
    granted_by: system_user
  )
  
  puts "Assigned permission: #{permission.namespace}/#{permission.controller}##{permission.action}"
end

puts "Completed! Admin role now has #{admin_role.permission_assignments.count} permissions"
