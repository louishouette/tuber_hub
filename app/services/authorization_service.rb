# frozen_string_literal: true

# Facade service that provides a unified interface to the authorization system
# This service delegates to the specialized services in the Authorization module
class AuthorizationService
  #===========================================================================
  # Permission Querying Methods - Delegated to QueryService
  #===========================================================================
  
  # Check if a user has permission for a specific action
  def self.user_has_permission?(user, namespace, controller, action, use_preloaded: false, farm: nil)
    Authorization::QueryService.user_has_permission?(user, namespace, controller, action, use_preloaded: use_preloaded, farm: farm)
  end
  
  # Preload permissions for a user
  def self.preload_user_permissions(user, namespaces: nil, farm: nil)
    Authorization::QueryService.preload_user_permissions(user, namespaces: namespaces, farm: farm)
  end
  
  # Returns all active permissions
  def self.active_permissions(exclude_system: true)
    Authorization::QueryService.active_permissions(exclude_system: exclude_system)
  end
  
  # Returns permissions grouped by namespace and controller
  def self.grouped_permissions(exclude_system: true)
    Authorization::QueryService.grouped_permissions(exclude_system: exclude_system)
  end
  
  #===========================================================================
  # Permission Management Methods - Delegated to ManagementService
  #===========================================================================
  
  # Refreshes the permissions by scanning controllers and clearing cache
  def self.refresh_permissions
    Authorization::ManagementService.refresh_permissions
  end
  
  # Discovers permissions from controllers and creates/updates them in the database
  def self.discover_permissions
    Authorization::ManagementService.discover_permissions
  end
  
  # Archives permissions that no longer exist in the application
  def self.archive_unused_permissions(discovered_permissions)
    Authorization::ManagementService.archive_unused_permissions(discovered_permissions)
  end
  
  # Creates an audit record for a permission change
  def self.audit_permission_change(permission, change_type, user: nil, previous_state: nil)
    Authorization::ManagementService.audit_permission_change(
      permission, change_type, user: user, previous_state: previous_state
    )
  end
  
  #===========================================================================
  # Audit Methods - Delegated to AuditService
  #===========================================================================
  
  # Gets audit history for a specific permission
  def self.permission_history(permission, limit = 50)
    Authorization::AuditService.permission_history(permission, limit)
  end
  
  # Gets audit history for a namespace
  def self.namespace_history(namespace, limit = 50)
    Authorization::AuditService.namespace_history(namespace, limit)
  end
  
  # Gets audit history for a controller
  def self.controller_history(namespace, controller, limit = 50)
    Authorization::AuditService.controller_history(namespace, controller, limit)
  end
  
  # Gets recent permission changes across the system
  def self.recent_changes(limit = 100, change_types = nil)
    Authorization::AuditService.recent_changes(limit, change_types)
  end
  
  # Gets statistics about permission changes
  def self.change_statistics(days = 30)
    Authorization::AuditService.change_statistics(days)
  end
  
  #===========================================================================
  # Cache Management Methods - Delegated to CacheService
  #===========================================================================
  
  # Clears all permission-related caches
  def self.clear_all_permission_caches
    Authorization::CacheService.clear_all_permission_caches
  end
  
  # Clears permission caches for a specific user
  def self.clear_user_permission_caches(user, farm: nil)
    Authorization::CacheService.clear_user_permission_caches(user, farm: farm)
  end
  
  # Clears permission caches for a specific permission
  def self.clear_permission_caches(namespace, controller, action)
    Authorization::CacheService.clear_permission_caches(namespace, controller, action)
  end
  
  # Clears permission caches when a role assignment changes
  def self.clear_role_assignment_caches(role_assignment)
    Authorization::CacheService.clear_role_assignment_caches(role_assignment)
  end
  
  # Clears permission caches when a permission assignment changes
  def self.clear_permission_assignment_caches(permission_assignment)
    Authorization::CacheService.clear_permission_assignment_caches(permission_assignment)
  end
  
  #===========================================================================
  # Helper Methods for Permissions
  #===========================================================================
  
  # Returns the standard CRUD action names
  # @return [Array<String>] array of standard CRUD action names
  def self.crud_actions
    Authorization::BaseService::CRUD_ACTIONS.keys
  end
  
  # Returns actions that can be controlled via Pundit policies
  # @param include_all [Boolean] whether to include all actions or just CRUD actions
  # @return [Array<String>] array of action names
  def self.pundit_controllable_actions(include_all: false)
    if include_all
      # Return all actions that have corresponding policy methods
      # This would include both standard CRUD and custom actions
      crud_actions + %w[search export import]
    else
      # Return just the standard CRUD actions
      crud_actions
    end
  end
  
  # Returns controllers that don't require authentication
  # @return [Array<String>] array of controller names
  def self.find_unauthenticated_controllers
    Authorization::ManagementService.send(:find_application_controllers).select do |controller_class|
      Authorization::ManagementService.send(:controller_requires_no_auth?, controller_class)
    end.map do |controller_class|
      namespace, controller = Authorization::ManagementService.send(:extract_namespace_and_controller, controller_class)
      namespace.present? ? "#{namespace}/#{controller}" : controller
    end
  end
end
