# db/seeds/farms.rb
# Seed file for creating farms

puts "Creating farms..."

# Find Admin User
admin_user = Hub::Admin::User.find_by(email_address: "louis@fbhinvest.fr")

if admin_user.nil?
  puts "Warning: Admin user not found. Farms will not be created."
else
  # Create main farm for admin user
  fbh_farm = Hub::Admin::Farm.find_or_initialize_by(handle: "FBH")
  fbh_farm.assign_attributes(
    name: "Truffière de Cément",
    description: "Premier producteur français de Tuber Melanosporum (truffe noire du Périgord)",
    active: true
  )

  if fbh_farm.save
    puts "Farm 'Truffière de Cément' created"
    
    # Associate admin user with farm if not already done
    unless admin_user.farms.include?(fbh_farm)
      farm_user = Hub::Admin::FarmUser.create!(
        user: admin_user, 
        farm: fbh_farm
      )
      puts "Associated admin user with farm as admin"
    end
  else
    puts "Failed to create Truffière de Cément farm: #{truffiere_farm.errors.full_messages.join(', ')}"
  end

  # Create second farm 
  polmar_farm = Hub::Admin::Farm.find_or_initialize_by(handle: "POLMAR")
  polmar_farm.assign_attributes(
    name: "POLMAR",
    description: "Truffière en Espagne",
    active: true
  )

  if polmar_farm.save
    puts "Farm 'POLMAR' created"
    
    # Associate admin user with POLMAR farm if not already done
    unless admin_user.farms.include?(polmar_farm)
      farm_user = Hub::Admin::FarmUser.create!(
        user: admin_user, 
        farm: polmar_farm
      )
      puts "Associated admin user with POLMAR farm as admin"
    end
  else
    puts "Failed to create POLMAR farm: #{polmar_farm.errors.full_messages.join(', ')}"
  end
end

# You can add more farms here in the future

puts "Farm seeding completed!"
