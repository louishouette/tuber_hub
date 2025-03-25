require_relative "../config/environment"

# Script to add the admin role to a user

user = Hub::Admin::User.find_by(email_address: 'louis@fbhinvest.fr')
role = Hub::Admin::Role.find_by(name: 'admin')

if user && role
  has_role = user.roles.include?(role)
  puts "User: #{user.first_name} #{user.last_name} (#{user.email_address})"
  puts "Current roles: #{user.roles.pluck(:name).join(', ')}"
  
  if has_role
    puts "User already has admin role"
  else
    assignment = Hub::Admin::RoleAssignment.new(
      user: user,
      role: role,
      granted_by: user,
      global: true
    )
    
    if assignment.save
      puts "Admin role added successfully"
      puts "Updated roles: #{user.reload.roles.pluck(:name).join(', ')}"
    else
      puts "Failed to add role: #{assignment.errors.full_messages.join(', ')}"
    end
  end
else
  puts "User or role not found"
end
