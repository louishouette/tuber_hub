# frozen_string_literal: true

module Authorization
  # Base class for all authorization services
  # Provides common functionality and constants used across the authorization system
  class BaseService
    #===========================================================================
    # Constants
    #===========================================================================
    
    # System controllers and actions that should typically be excluded from user-facing permissions
    SYSTEM_CONTROLLERS = %w[application sessions passwords].freeze
    SYSTEM_ACTIONS = %w[authorize_namespace namespace_scope allowed_to? user_is_admin?].freeze
    
    # Standard CRUD actions with user-friendly descriptions
    CRUD_ACTIONS = {
      'index' => 'View list of records',
      'show' => 'View details of a record',
      'new' => 'Access new record form',
      'create' => 'Create a new record',
      'edit' => 'Access edit record form',
      'update' => 'Update an existing record',
      'destroy' => 'Delete a record'
    }.freeze
    
    # Application root path used to determine if a controller belongs to the application
    APP_ROOT_PATH = Rails.root.join('app').to_s.freeze
    
    # Cache expiration times
    PERMISSION_CACHE_DURATION = 1.hour
    GROUP_CACHE_DURATION = 15.minutes
    NAMESPACE_CACHE_DURATION = 1.hour
  end
end
