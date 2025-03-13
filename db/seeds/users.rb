# db/seeds/users.rb
# Seed file for creating users

puts "Creating users..."

# Create admin role if it doesn't exist
admin_role = Hub::Admin::Role.find_or_create_by!(name: 'admin') do |role|
  role.description = 'Administrator with full system access'
  puts "Created admin role"
end

# Create admin user
admin = Hub::Admin::User.find_or_initialize_by(email_address: "louis@fbhinvest.fr")
admin.assign_attributes(
  first_name: "Louis",
  last_name: "Houette",
  password: "passw0rd"
)

if admin.save
  puts "Admin user 'Louis Houette' created"
  
  # Assign admin role to user if not already assigned
  unless admin.role_assignments.exists?(role: admin_role)
    admin.role_assignments.create!(role: admin_role)
    puts "Assigned admin role to user"
  end
else
  puts "Failed to create admin user: #{admin.errors.full_messages.join(', ')}"
end

# You can add more users here in the future

puts "User seeding completed!"
