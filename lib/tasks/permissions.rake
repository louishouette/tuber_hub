# frozen_string_literal: true

# Rake tasks for permission management - uses PermissionService for implementation
namespace :permissions do
  desc "Discover and seed permissions from controllers"
  task discover: :environment do
    puts "Discovering permissions from controllers..."
    
    # Use the PermissionService to discover permissions
    count = PermissionService.refresh_permissions
    
    # Get counts for display
    active_count = Hub::Admin::Permission.where(status: 'active').count
    legacy_count = Hub::Admin::Permission.where(status: 'legacy').count
    
    puts "\nPermissions discovery completed:"
    puts "  #{active_count} active permissions"
    puts "  #{legacy_count} legacy permissions marked"
  end
  
  desc "Assign all permissions to the admin role"
  task assign_to_admin: :environment do
    puts "Assigning permissions to Admin role..."
    
    # Use the PermissionService to assign permissions
    assigned_count = PermissionService.assign_all_to_admin
    
    # Get total counts for display
    total_count = Hub::Admin::Permission.where(status: 'active').count
    existing_count = total_count - assigned_count
    
    puts "Completed assigning permissions to Admin role:"
    puts "  #{assigned_count} new permissions assigned"
    puts "  #{existing_count} permissions already assigned"
  end
  
  desc "Run complete permissions setup (discover + assign to admin)"
  task setup: [:discover, :assign_to_admin] do
    puts "Permissions setup completed successfully."
  end
end
