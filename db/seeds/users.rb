# db/seeds/users.rb
# Seed file for creating users

puts "Creating users..."

# Create admin user
admin = User.find_or_initialize_by(email_address: "louis@fbhinvest.fr")
admin.assign_attributes(
  first_name: "Louis",
  last_name: "Houette",
  password: "passw0rd"
)

if admin.save
  puts "Admin user 'Louis Houette' created"
else
  puts "Failed to create admin user: #{admin.errors.full_messages.join(', ')}"
end

# You can add more users here in the future

puts "User seeding completed!"
