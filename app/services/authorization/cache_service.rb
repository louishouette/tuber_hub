# frozen_string_literal: true

module Authorization
  # Service for managing permission caches
  # Handles cache invalidation and clearing for permission-related caches
  class CacheService < BaseService
    #===========================================================================
    # Cache Management Methods
    #===========================================================================
    
    # Clears all permission-related caches
    # @return [void]
    def self.clear_all_permission_caches
      # Clear the general permissions cache
      Rails.cache.delete('grouped_permissions')
      Rails.cache.delete('main_namespaces')
      
      # Clear all user permission caches (both global and farm-specific)
      Rails.cache.delete_matched("user_*_permission_*")
      Rails.cache.delete_matched("user_*_farm_*_permission_*")
    end
    
    # Clears permission caches for a specific user
    # @param user [Hub::Admin::User] the user whose caches to clear
    # @param farm [Hub::Admin::Farm, nil] optional farm to clear farm-specific caches for
    # @return [void]
    def self.clear_user_permission_caches(user, farm: nil)
      return unless user&.id
      
      # Clear instance variable caches
      if farm.present?
        # Clear farm-specific cache on user instance if it exists
        user.remove_instance_variable("@preloaded_farm_#{farm.id}_permissions") if user.instance_variable_defined?("@preloaded_farm_#{farm.id}_permissions")
        # Clear farm-specific cache in Rails cache
        Rails.cache.delete_matched("user_#{user.id}_farm_#{farm.id}_permission_*")
      else
        # Clear global permission cache on user instance
        user.remove_instance_variable(:@preloaded_permissions) if user.instance_variable_defined?(:@preloaded_permissions)
        # Clear all user permission caches (both global and farm-specific)
        Rails.cache.delete_matched("user_#{user.id}_permission_*")
        Rails.cache.delete_matched("user_#{user.id}_farm_*_permission_*")
      end
    end
    
    # Clears permission caches for a specific permission
    # @param namespace [String] namespace of the permission
    # @param controller [String] controller of the permission
    # @param action [String] action of the permission
    # @return [void]
    def self.clear_permission_caches(namespace, controller, action)
      # Create a pattern to match any user's cache for this permission
      cache_pattern = "user_*_permission_#{namespace}:#{controller}:#{action}"
      farm_cache_pattern = "user_*_farm_*_permission_#{namespace}:#{controller}:#{action}"
      
      # Delete all matching caches
      Rails.cache.delete_matched(cache_pattern)
      Rails.cache.delete_matched(farm_cache_pattern)
      
      # Also clear the grouped permissions cache
      Rails.cache.delete('grouped_permissions')
    end
    
    # Clears permission caches when a role assignment changes
    # @param role_assignment [Hub::Admin::RoleAssignment] the role assignment that changed
    # @return [void]
    def self.clear_role_assignment_caches(role_assignment)
      # Clear caches for the affected user
      user = role_assignment.user
      return unless user
      
      # If this is a farm-specific role, clear only that farm's cache
      if role_assignment.farm_id.present?
        farm = role_assignment.farm
        clear_user_permission_caches(user, farm: farm) if farm
      else
        # Otherwise clear all caches for this user
        clear_user_permission_caches(user)
      end
    end
    
    # Clears permission caches when a permission assignment changes
    # @param permission_assignment [Hub::Admin::PermissionAssignment] the assignment that changed
    # @return [void]
    def self.clear_permission_assignment_caches(permission_assignment)
      # Get the permission and role details
      permission = permission_assignment.permission
      role = permission_assignment.role
      
      return unless permission && role
      
      # Clear cache for the specific permission
      clear_permission_caches(permission.namespace, permission.controller, permission.action)
      
      # Also clear caches for all users with this role
      role.users.each do |user|
        clear_user_permission_caches(user)
      end
    end
  end
end
