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
  
  desc "Remove legacy permissions from the database"
  task remove_legacy: :environment do
    puts "Removing legacy permissions..."
    
    # Count legacy permissions before removal
    legacy_count_before = Hub::Admin::Permission.where(status: 'legacy').count
    
    if legacy_count_before.zero?
      puts "No legacy permissions found to remove."
    else
      # Remove all legacy permissions
      Hub::Admin::Permission.where(status: 'legacy').destroy_all
      
      # Count remaining permissions for verification
      remaining_count = Hub::Admin::Permission.count
      
      puts "\nLegacy permissions removal completed:"
      puts "  #{legacy_count_before} legacy permissions removed"
      puts "  #{remaining_count} permissions remaining in the system"
    end
  end
end
