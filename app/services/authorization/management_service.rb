# frozen_string_literal: true

module Authorization
  # Service for managing permissions
  # Handles permission discovery, creation, and management operations
  class ManagementService < BaseService
    #===========================================================================
    # Permission Management Methods
    #===========================================================================
    
    # Refreshes the permissions by scanning controllers and clearing cache
    # @return [Boolean] whether the operation succeeded
    def self.refresh_permissions
      # Run the permissions discovery
      permission_count = discover_permissions
      
      # Clear all permission-related caches systematically
      CacheService.clear_all_permission_caches
      
      # Log successful refresh
      Rails.logger.info("Permission refresh completed: #{permission_count} active permissions")
      true
    rescue => e
      # Log failure with detailed error information
      Rails.logger.error("Permission refresh failed: #{e.message}\n#{e.backtrace.join('\n')}")
      false
    end

    # Discovers permissions from the application's controllers
    # Creates new permissions if they don't exist, or updates existing ones
    # @return [Integer] the number of active permissions after discovery
    def self.discover_permissions
      # Get all controller classes in the application
      controller_classes = find_application_controllers
      
      # Process each controller to extract permissions
      controller_permissions = []
      
      controller_classes.each do |controller_class|
        # Skip controllers that don't require authentication
        next if controller_requires_no_auth?(controller_class)
        
        # Get namespace and controller name from class
        namespace, controller = extract_namespace_and_controller(controller_class)
        
        # Skip system controllers
        next if SYSTEM_CONTROLLERS.include?(controller)
        
        # Get all public instance methods from controller that aren't rails internals
        controller_actions = get_controller_actions(controller_class)
        
        # Filter out system actions
        controller_actions -= SYSTEM_ACTIONS
        
        # Add permissions for each action
        controller_actions.each do |action|
          # Skip private/protected methods or before/after filters
          next if action.start_with?('_') || action.include?('=')
          
          controller_permissions << {
            namespace: namespace,
            controller: controller,
            action: action
          }
        end
      end
      
      # Update database with discovered permissions and audit the changes
      store_permissions(controller_permissions)
    end
    
    # Creates an audit trail entry for a permission change
    # @param permission [Hub::Admin::Permission] the permission being changed
    # @param change_type [String] the type of change (created, updated, archived, etc.)
    # @param user [Hub::Admin::User, nil] the user making the change (nil for system changes)
    # @param previous_state [Hash, nil] the previous state of the permission if applicable
    # @return [Hub::Admin::PermissionAudit] the created audit record
    def self.audit_permission_change(permission, change_type, user: nil, previous_state: nil)
      Hub::Admin::PermissionAudit.record_change(
        permission,
        change_type,
        user: user,
        previous_state: previous_state
      )
    end
    
    # Creates audit trail entries for bulk permission changes
    # @param permissions [Array<Hub::Admin::Permission>] the permissions being changed
    # @param change_type [String] the type of change (created, updated, archived, etc.)
    # @return [Integer] the number of audit records created
    def self.audit_bulk_permission_changes(permissions, change_type)
      Hub::Admin::PermissionAudit.record_bulk_change(permissions, change_type)
    end
    
    # Archives permissions that no longer exist in the application
    # @param discovered_permissions [Array<Hash>] array of hashes with namespace, controller, action
    # @return [Integer] the number of archived permissions
    def self.archive_unused_permissions(discovered_permissions)
      # Extract unique permission identifiers from discovered permissions
      discovered_keys = discovered_permissions.map do |p|
        "#{p[:namespace]}|#{p[:controller]}|#{p[:action]}"
      end.to_set
      
      # Find permissions in the database that are not in the discovered set
      permissions_to_archive = Hub::Admin::Permission.where(status: 'active').select do |p|
        permission_key = "#{p.namespace}|#{p.controller}|#{p.action}"
        !discovered_keys.include?(permission_key)
      end
      
      # Archive the unused permissions and record audits
      permissions_to_archive.each do |p|
        # Store previous state for audit
        previous_state = {
          status: p.status,
          archived_at: p.archived_at
        }
        
        # Update permission status
        p.update(status: 'archived', archived_at: Time.zone.now)
        
        # Create audit record
        audit_permission_change(p, 'archived', previous_state: previous_state)
      end
      
      # Create bulk audit entry if multiple permissions were archived
      audit_bulk_permission_changes(permissions_to_archive, 'archived') if permissions_to_archive.size > 5
      
      # Return the count of archived permissions
      permissions_to_archive.size
    end

    private

    # Finds all application controller classes
    # @return [Array<Class>] array of controller classes
    def self.find_application_controllers
      Rails.application.eager_load! if Rails.env.development?
      
      controllers = []
      ObjectSpace.each_object(Class) do |klass|
        next unless klass < ActionController::Base
        next if klass.abstract_class?
        
        # Only include controllers from our application, not from gems
        controllers << klass if klass.instance_methods(false).any? && 
                                 klass.name&.include?('Controller') && 
                                 (klass.name.start_with?('Hub') || klass.name.start_with?('Public'))
      end
      
      controllers
    end
    
    # Determines if a controller requires no authentication
    # @param controller_class [Class] the controller class to check
    # @return [Boolean] whether the controller requires no authentication
    def self.controller_requires_no_auth?(controller_class)
      # Controllers that skip authentication via their namespace or explicit configuration
      return true if controller_class.name&.start_with?('Public')
      return true if controller_class.try(:skip_authentication?)
      
      # Check for skip_before_action :require_login or similar
      controller_class_ancestors = controller_class.ancestors.select { |a| a.is_a?(Class) }
      
      controller_class_ancestors.any? do |ancestor|
        next unless ancestor.respond_to?(:_process_action_callbacks)
        
        ancestor._process_action_callbacks.any? do |callback|
          callback.kind == :before && 
          callback.filter.to_s.include?('require_login') && 
          callback.instance_variable_get(:@if).blank? && 
          callback.instance_variable_get(:@unless).blank? && 
          callback.instance_variable_get(:@prepend) == true
        end
      end
    end
    
    # Extracts namespace and controller name from a controller class
    # @param controller_class [Class] the controller class
    # @return [Array<String, String>] namespace and controller name
    def self.extract_namespace_and_controller(controller_class)
      controller_path = controller_class.controller_path
      
      if controller_path.include?('/')
        namespace = controller_path.split('/')[0..-2].join('/')
        controller = controller_path.split('/').last
      else
        namespace = ''
        controller = controller_path
      end
      
      [namespace, controller]
    end
    
    # Gets all controller actions for a controller class
    # @param controller_class [Class] the controller class
    # @return [Array<String>] array of action names
    def self.get_controller_actions(controller_class)
      # Get public instance methods defined on this class
      # Exclude methods inherited from ApplicationController
      own_instance_methods = controller_class.instance_methods(false)
      
      # Get all CRUD action methods plus any custom methods
      # that aren't part of Rails' internal mechanisms
      action_methods = own_instance_methods.map(&:to_s).select do |method_name|
        # Include standard CRUD actions and custom actions
        # Exclude Rails internal methods (starting with _ or ending with = or ?)
        !method_name.start_with?('_') && 
        !method_name.end_with?('=') && 
        !method_name.end_with?('?') && 
        method_name != 'initialize'
      end
      
      # Add standard RESTful actions if the controller has them
      CRUD_ACTIONS.keys.each do |action|
        next if action_methods.include?(action) # Skip if already included
        action_methods << action if controller_class.action_methods.include?(action)
      end
      
      action_methods.uniq
    end
    
    # Stores discovered permissions in the database
    # @param controller_permissions [Array<Hash>] array of permission hashes
    # @return [Integer] the number of active permissions
    def self.store_permissions(controller_permissions)
      # Track newly created permissions for bulk audit
      newly_created_permissions = []
      updated_permissions = []
      
      controller_permissions.each do |permission_data|
        permission = Hub::Admin::Permission.find_or_initialize_by(
          namespace: permission_data[:namespace],
          controller: permission_data[:controller],
          action: permission_data[:action]
        )
        
        # Check if this is a new permission or needs updating
        is_new = !permission.persisted?
        needs_update = permission.persisted? && (permission.status != 'active' || permission.discovered_at.nil?)
        
        # Save the previous state for audit purposes if updating
        previous_state = needs_update ? {
          status: permission.status,
          description: permission.description,
          discovered_at: permission.discovered_at
        } : nil
        
        # Update or create the permission
        if is_new || needs_update
          description = generate_permission_description(permission_data) 
          
          # Update the permission
          permission.update(
            description: description,
            status: 'active',
            discovered_at: Time.zone.now
          )
          
          # Add to appropriate tracking list for audit
          if is_new
            newly_created_permissions << permission
            # Individual audit for new permissions
            audit_permission_change(permission, 'created')
          elsif needs_update
            updated_permissions << permission
            # Individual audit for status changes (e.g., from archived to active)
            audit_permission_change(permission, 'updated', previous_state: previous_state)
          end
        end
      end
      
      # Create bulk audit entries if many permissions were affected
      audit_bulk_permission_changes(newly_created_permissions, 'created') if newly_created_permissions.size > 5
      audit_bulk_permission_changes(updated_permissions, 'updated') if updated_permissions.size > 5
      
      # Archive permissions that no longer exist
      archive_unused_permissions(controller_permissions)
      
      # Return the count of active permissions
      Hub::Admin::Permission.where(status: 'active').count
    end
    
    # Generates a human-readable description for a permission
    # @param permission_data [Hash] hash with namespace, controller, action
    # @return [String] the generated description
    def self.generate_permission_description(permission_data)
      # Use predefined descriptions for standard CRUD actions
      action = permission_data[:action]
      namespace = permission_data[:namespace]
      controller = permission_data[:controller]
      
      if CRUD_ACTIONS.key?(action)
        "#{CRUD_ACTIONS[action]} in #{namespace}/#{controller}"
      else
        "#{action.humanize} in #{namespace}/#{controller}"
      end
    end
  end
end
