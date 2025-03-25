require_relative "../config/environment"

# Script to fix users without farm associations and roles

# Find the FBH farm or exit if not found
fbh_farm = Hub::Admin::Farm.find_by(handle: 'fbh')
if fbh_farm.nil?
  puts "\nERROR: Farm with handle 'fbh' not found. Please create it first."
  exit 1
end

# Find or create the OP role
op_role = Hub::Admin::Role.find_by(name: 'OP')
if op_role.nil?
  op_role = Hub::Admin::Role.new(name: 'OP', description: 'Ouvrier Polyvalent')
  if op_role.save
    puts "Created 'OP' role successfully."
  else
    puts "\nERROR: Failed to create 'OP' role: #{op_role.errors.full_messages.join(', ')}"
    exit 1
  end
end

# Find admin user to be the granter
admin_user = Hub::Admin::User.joins(:roles).where(hub_admin_roles: { name: 'admin' }).first
if admin_user.nil?
  # If no admin user exists, use the first user
  admin_user = Hub::Admin::User.first
  if admin_user.nil?
    puts "\nERROR: No users found in the system to act as granter."
    exit 1
  end
end

puts "\nStarting fix_user_farm_roles script at #{Time.zone.now}"
puts "Found FBH farm: #{fbh_farm.name} (ID: #{fbh_farm.id})"
puts "Using OP role: ID #{op_role.id}"
puts "Using granter: #{admin_user.first_name} #{admin_user.last_name} (ID: #{admin_user.id})"

# Get users without farms
users_without_farms = Hub::Admin::User.all.select do |user|
  user.farms.empty?
end

puts "\nFound #{users_without_farms.count} users without farm associations:"

# Associate users with the FBH farm and assign OP role if needed
users_without_farms.each do |user|
  puts "Processing user: #{user.first_name} #{user.last_name} (#{user.email_address})"
  
  # Add user to FBH farm
  farm_user = Hub::Admin::FarmUser.new(farm: fbh_farm, user: user)
  if farm_user.save
    puts "  ✓ Added to FBH farm"
  else
    puts "  ✗ Failed to add to FBH farm: #{farm_user.errors.full_messages.join(', ')}"
  end
  
  # Add OP role if user has no roles
  if user.roles.empty?
    assignment = Hub::Admin::RoleAssignment.new(
      user: user,
      role: op_role,
      granted_by: admin_user,
      global: true
    )
    
    if assignment.save
      puts "  ✓ Assigned OP role"
    else
      puts "  ✗ Failed to assign OP role: #{assignment.errors.full_messages.join(', ')}"
    end
  else
    puts "  ℹ User already has roles: #{user.roles.pluck(:name).join(', ')}"
  end
end

puts "\nScript completed at #{Time.zone.now}"
