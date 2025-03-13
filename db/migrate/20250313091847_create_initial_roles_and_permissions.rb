class CreateInitialRolesAndPermissions < ActiveRecord::Migration[8.0]
  def up
    # Skip if no tables yet
    return unless table_exists?(:hub_admin_roles) && table_exists?(:hub_admin_permissions) && table_exists?(:hub_admin_users)
    
    # Create admin role
    admin_role = Hub::Admin::Role.create!(
      name: 'Admin',
      description: 'Full access to all features'
    )
    
    # Find or create admin user
    admin_user = Hub::Admin::User.find_by(email_address: 'louis@fbhinvest.fr')
    
    if admin_user
      # Assign admin role to the user
      Hub::Admin::RoleAssignment.create!(
        user: admin_user,
        role: admin_role,
        granted_by: admin_user # Self-granted initially
      )
      puts "Admin role assigned to existing user: #{admin_user.email_address}"
    else
      puts "Warning: User with email 'louis@fbhinvest.fr' not found. Admin role was created but not assigned."
    end
  end

  def down
    # This is a one-way migration - we don't want to delete roles and permissions
    # if the migration is rolled back
  end
end
