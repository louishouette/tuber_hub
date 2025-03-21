# frozen_string_literal: true

module Authorization
  # Service for querying user permissions
  # Handles the logic for checking if users have specific permissions
  class QueryService < BaseService
    #===========================================================================
    # Permission Querying Methods
    #===========================================================================
    
    # Checks if a user has a specific permission based on their roles
    # Fast-paths for admin users and unauthenticated access
    # This is the central method for all permission checks in the application.
    # @param user [Hub::Admin::User, nil] the user to check permissions for
    # @param namespace [String] controller namespace
    # @param controller [String] controller name
    # @param action [String] action name
    # @param use_preloaded [Boolean] whether to use preloaded permissions if available
    # @param farm [Hub::Admin::Farm, nil] the farm to check farm-specific permissions for
    # @return [Boolean] whether the user has permission
    def self.user_has_permission?(user, namespace, controller, action, use_preloaded: false, farm: nil)
      # Fast path for admin users and nil users
      return true if user&.admin? # Admin users can do everything
      return false unless user    # No user, no permissions
      
      # Format parameters consistently
      namespace = namespace.to_s
      controller = controller.to_s
      action = action.to_s
      
      # Try to use preloaded permissions if requested and available
      if use_preloaded
        # Check for farm-specific preloaded permissions if a farm was specified
        if farm.present? && user.instance_variable_defined?("@preloaded_farm_#{farm.id}_permissions")
          permission_key = "#{namespace}:#{controller}:#{action}"
          return user.instance_variable_get("@preloaded_farm_#{farm.id}_permissions").include?(permission_key)
        # Otherwise check regular global permissions
        elsif user.instance_variable_defined?(:@preloaded_permissions)
          permission_key = "#{namespace}:#{controller}:#{action}"
          return user.instance_variable_get(:@preloaded_permissions).include?(permission_key)
        end
      end
      
      # Generate a unique cache key for this permission check
      farm_key = farm.present? ? "_farm_#{farm.id}" : ""
      cache_key = "user_#{user.id}_permission_#{namespace}:#{controller}:#{action}#{farm_key}"
      
      Rails.cache.fetch(cache_key, expires_in: PERMISSION_CACHE_DURATION) do
        # Get the user's role IDs efficiently, considering farm-specific permissions
        if farm.present?
          # When a farm is specified, check both global roles and farm-specific roles
          role_ids = user.role_assignments
                         .where('(farm_id = ? AND global = ?) OR global = ?', farm.id, false, true)
                         .active
                         .pluck(:role_id)
        else
          # When no farm is specified, only check global roles (not farm-specific ones)
          role_ids = user.role_assignments
                         .where(global: true)
                         .active
                         .pluck(:role_id)
        end
        
        return false if role_ids.empty?
        
        # Query whether any of the user's roles have this permission
        # Account for both unlimited and non-expired permissions
        Hub::Admin::Permission
          .joins(:permission_assignments)
          .where(status: 'active')
          .where(namespace: namespace, controller: controller, action: action)
          .where(hub_admin_permission_assignments: { role_id: role_ids })
          .where(
            'hub_admin_permission_assignments.expires_at IS NULL OR hub_admin_permission_assignments.expires_at > ?', 
            Time.zone.now
          )
          .exists?
      end
    end
    
    # Preloads all permissions for a user to avoid N+1 queries
    # @param user [Hub::Admin::User] the user to preload permissions for
    # @param namespaces [Array<String>] optional array of namespaces to limit preloading
    # @param farm [Hub::Admin::Farm, nil] optional farm to preload farm-specific permissions for
    # @return [Array<String>] array of permission strings in format "namespace:controller:action"
    def self.preload_user_permissions(user, namespaces: nil, farm: nil)
      return [] unless user && !user.admin?
      
      # Get user's role IDs based on farm context
      if farm.present?
        # When a farm is specified, check both global roles and farm-specific roles
        role_ids = user.role_assignments
                      .where('(farm_id = ? AND global = ?) OR global = ?', farm.id, false, true)
                      .active
                      .pluck(:role_id)
      else
        # When no farm is specified, only check global roles (not farm-specific ones)
        role_ids = user.role_assignments
                      .where(global: true)
                      .active
                      .pluck(:role_id)
      end
      
      return [] if role_ids.empty?
      
      # Build the query for the user's permissions, optimized with proper indices
      permissions_query = Hub::Admin::Permission
        .select(:namespace, :controller, :action)
        .distinct
        .joins(:permission_assignments)
        .where(status: 'active')
        .where(hub_admin_permission_assignments: { role_id: role_ids })
        .where(
          'hub_admin_permission_assignments.expires_at IS NULL OR hub_admin_permission_assignments.expires_at > ?', 
          Time.zone.now
        )
      
      # Add namespace filter if specified
      permissions_query = permissions_query.where(namespace: namespaces) if namespaces.present?
      
      # Execute query and format results as permission strings
      permission_strings = permissions_query.map do |p|
        "#{p.namespace}:#{p.controller}:#{p.action}"
      end
      
      # Store on user instance for later use
      # If farm-specific, store in a farm-specific variable
      if farm.present?
        user.instance_variable_set("@preloaded_farm_#{farm.id}_permissions", permission_strings)
      else
        user.instance_variable_set(:@preloaded_permissions, permission_strings)
      end
      
      # Return the permission strings
      permission_strings
    end
    
    # Returns all active permissions, with optional filtering
    # @param exclude_system [Boolean] whether to exclude system controllers and actions
    # @return [ActiveRecord::Relation] collection of permissions
    def self.active_permissions(exclude_system: true)
      query = Hub::Admin::Permission.where(status: 'active')
      
      if exclude_system
        query = query.where.not(controller: SYSTEM_CONTROLLERS)
                   .where.not(action: SYSTEM_ACTIONS)
      end
      
      query.order(:namespace, :controller, :action)
    end
    
    # Returns permissions grouped by namespace and controller for easier navigation
    # Uses the active_permissions method to ensure consistency
    # @param exclude_system [Boolean] whether to exclude system controllers and actions
    # @return [Hash] nested hash of permissions grouped by namespace and controller
    def self.grouped_permissions(exclude_system: true)
      Rails.cache.fetch('grouped_permissions', expires_in: GROUP_CACHE_DURATION) do
        active_permissions(exclude_system: exclude_system)
          .group_by(&:namespace)
          .transform_values { |perms| perms.group_by(&:controller) }
      end
    end
  end
end
