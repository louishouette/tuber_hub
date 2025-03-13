namespace :permissions do
  desc "Discover and seed permissions from controllers"
  task discover: :environment do
    puts "Discovering permissions from controllers..."
    
    # Store count of permissions for reporting
    new_count = 0
    updated_count = 0
    legacy_count = 0
    
    # Start with Rails controller paths
    controller_paths = Rails.root.join('app', 'controllers').glob('**/*_controller.rb')
    
    # Track all discovered permissions to mark others as legacy
    discovered_permissions = []
    
    controller_paths.each do |path|
      # Skip concerns directory
      next if path.to_s.include?('/concerns/')
      
      # Extract controller name and namespace
      relative_path = path.relative_path_from(Rails.root.join('app', 'controllers')).to_s
      controller_name = relative_path.sub(/\.rb$/, '').sub(/_controller$/, '')
      
      # Determine namespace by checking the module nesting
      namespace = nil
      if controller_name.include?('/')
        namespace = controller_name.split('/')[0..-2].join('/')
        controller_name = controller_name.split('/').last
      end
      
      # Use a default namespace for controllers without a namespace
      namespace ||= 'app'
      
      # Get the controller class
      begin
        controller_class = (controller_name + '_controller').camelize.constantize
      rescue NameError
        puts "Warning: Could not load controller class for #{controller_name}"
        next
      end
      
      # Discover actions from controller public instance methods
      actions = controller_class.action_methods.to_a
      
      # Common actions to expect
      common_actions = %w[index show new create edit update destroy]
      
      # Add common actions if they might be inherited
      if controller_class < ApplicationController
        actions_to_check = common_actions - actions
        actions_to_check.each do |action|
          if controller_class.method_defined?(action)
            actions << action
          end
        end
      end
      
      actions.each do |action|
        # Skip internal Rails actions
        next if action.starts_with?('_')
        
        # Create or update permission
        permission_attrs = {
          namespace: namespace,
          controller: controller_name,
          action: action,
          status: Hub::Admin::Permission::STATUSES[:active]
        }
        
        permission = Hub::Admin::Permission.find_or_initialize_by(
          namespace: permission_attrs[:namespace],
          controller: permission_attrs[:controller],
          action: permission_attrs[:action]
        )
        
        if permission.new_record?
          permission.update!(permission_attrs)
          new_count += 1
          puts "  Created permission: #{namespace}:#{controller_name}:#{action}"
        elsif permission.status != permission_attrs[:status]
          permission.update!(status: permission_attrs[:status])
          updated_count += 1
          puts "  Updated permission: #{namespace}:#{controller_name}:#{action}"
        end
        
        discovered_permissions << permission.id
      end
    end
    
    # Mark undiscovered permissions as legacy
    Hub::Admin::Permission.where.not(id: discovered_permissions).update_all(
      status: Hub::Admin::Permission::STATUSES[:legacy]
    )
    
    legacy_count = Hub::Admin::Permission.where(status: Hub::Admin::Permission::STATUSES[:legacy]).count
    
    puts "\nPermissions discovery completed:"
    puts "  #{new_count} new permissions created"
    puts "  #{updated_count} permissions updated"
    puts "  #{legacy_count} legacy permissions marked"
    puts "  #{discovered_permissions.size} total active permissions"
  end
  
  desc "Assign all permissions to the admin role"
  task assign_to_admin: :environment do
    # Find the admin role using case-insensitive search
    admin_role = Hub::Admin::Role.where('LOWER(name) = ?', 'admin').first
    
    unless admin_role
      admin_role = Hub::Admin::Role.create!(
        name: 'Admin',
        description: 'Administrator role with access to all system functions'
      )
      puts "Created Admin role"
    else
      puts "Found existing Admin role: #{admin_role.name}"
    end
    
    # Try to find an admin user to grant permissions
    admin_user = Hub::Admin::User.first
    
    unless admin_user
      puts "Error: No users found in the system"
      exit 1
    end
    
    puts "Using user #{admin_user.email_address} to grant permissions"
    
    # Find all active permissions
    permissions = Hub::Admin::Permission.where(status: Hub::Admin::Permission::STATUSES[:active])
    
    puts "Assigning #{permissions.count} permissions to Admin role..."
    
    assigned_count = 0
    exists_count = 0
    
    # Create the permission assignments model instances
    assignment_records = []
    
    permissions.each do |permission|
      # Check if this permission is already assigned
      if admin_role.permission_assignments.exists?(permission_id: permission.id)
        exists_count += 1
        next
      end
      
      # Create a new assignment record
      assignment_records << Hub::Admin::PermissionAssignment.new(
        role: admin_role,
        permission: permission,
        granted_by: admin_user
      )
      assigned_count += 1
    end
    
    # Insert the assignment records if any exist
    if assignment_records.any?
      Hub::Admin::PermissionAssignment.insert_all(
        assignment_records.map do |record|
          {
            role_id: record.role_id,
            permission_id: record.permission_id,
            granted_by_id: record.granted_by_id,
            created_at: Time.zone.now,
            updated_at: Time.zone.now
          }
        end
      )
    end
    
    puts "Completed assigning permissions to Admin role:"
    puts "  #{assigned_count} new permissions assigned"
    puts "  #{exists_count} permissions already assigned"
  end
  
  desc "Run complete permissions setup (discover + assign to admin)"
  task setup: :environment do
    Rake::Task['permissions:discover'].invoke
    Rake::Task['permissions:assign_to_admin'].invoke
  end
end
