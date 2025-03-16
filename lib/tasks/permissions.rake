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
end
