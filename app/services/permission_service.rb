# frozen_string_literal: true

# Service class for handling database-driven permissions and integrating with Pundit policies
# Manages permission discovery, assignment, and access control throughout the application
class PermissionService
  # System controllers and actions that should typically be excluded from user-facing permissions
  SYSTEM_CONTROLLERS = %w[application sessions passwords].freeze
  SYSTEM_ACTIONS = %w[authorize_namespace namespace_scope allowed_to? user_is_admin?].freeze
  MAIN_NAMESPACES = %w[hub hub/admin club marketplace public].freeze
  ROOT_CONTROLLERS = %w[hub club marketplace public].freeze
  
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
    # Use Solid Cache (Rails 8) for better performance and reliability
    Rails.cache.fetch('grouped_permissions', expires_in: 15.minutes) do
      active_permissions(exclude_system: exclude_system)
        .group_by(&:namespace)
        .transform_values { |perms| perms.group_by(&:controller) }
    end
  end
  
  # Checks if a user has a specific permission based on their roles
  # Fast-paths for admin users and unauthenticated access
  # @param user [User] the user to check permissions for
  # @param namespace [String] controller namespace
  # @param controller [String] controller name
  # @param action [String] action name
  # @return [Boolean] whether the user has permission
  def self.user_has_permission?(user, namespace, controller, action)
    # Fast path for admin users and nil users
    return true if user&.admin? # Admin users can do everything
    return false unless user    # No user, no permissions
    
    # Generate a unique cache key for this permission check
    cache_key = "user_#{user.id}_permission_#{namespace}:#{controller}:#{action}"
    
    # Use Solid Cache (Rails 8) for caching with optimal compression
    Rails.cache.fetch(cache_key, expires_in: 1.hour) do
      # Get the user's role IDs efficiently
      role_ids = user.roles.pluck(:id)
      return false if role_ids.empty?
      
      # Query whether any of the user's roles have this permission
      # and ensure the permission hasn't expired
      permission_exists = Hub::Admin::Permission
        .joins(:permission_assignments)
        .where(namespace: namespace, controller: controller, action: action, status: 'active')
        .where(hub_admin_permission_assignments: { role_id: role_ids })
        .where(hub_admin_permission_assignments: { expires_at: [nil, Time.zone.now..] })
        .exists?
        
      # Return boolean result for caching
      permission_exists
    end
  end
  
  # Refreshes the permissions by scanning controllers and clearing cache
  # @return [Boolean] whether the operation succeeded
  def self.refresh_permissions
    # Run the permissions discovery
    permission_count = discover_permissions
    
    # Clear all permission-related caches using Solid Cache pattern
    # This is more efficient than the older delete_matched approach
    Rails.cache.delete('grouped_permissions')
    Rails.cache.delete_matched("user_*_permission_*")
    
    # Log successful refresh
    Rails.logger.info("Permission refresh completed: #{permission_count} active permissions")
    true
  rescue => e
    # Log failure with detailed error information
    Rails.logger.error("Permission refresh failed: #{e.message}\n#{e.backtrace.join('\n')}")
    false
  end

  # Discovers all controller actions and creates permissions records
  # @return [Integer] the count of active permissions after discovery
  def self.discover_permissions
    # Ensure all controllers are loaded
    Rails.application.eager_load!
    
    # Get all application controllers, skipping abstract ones
    controllers = ApplicationController.descendants.reject(&:abstract?)
    
    # Filter out controllers that don't require authentication
    authenticate_required_controllers = controllers.reject { |c| controller_skips_authentication?(c) }
    
    # Track statistics for logging
    processed_count = 0
    new_count = 0
    
    # Process each controller and create permissions in batches
    authenticate_required_controllers.each do |controller|
      namespace, controller_name = extract_namespace_and_controller(controller.name)
      new_permissions = process_controller_actions(controller, namespace, controller_name)
      
      processed_count += 1
      new_count += new_permissions
    end
    
    # Log discovery statistics
    Rails.logger.info("Processed #{processed_count} controllers, added #{new_count} new permissions")
    
    # Return the count of active permissions
    Hub::Admin::Permission.where(status: 'active').count
  end
  
  # Check if a controller skips authentication (doesn't require authenticated users)
  # This method determines if a controller allows unauthenticated access by examining
  # its inheritance chain and source code
  # @param controller [Class] the controller class to check
  # @return [Boolean] whether the controller skips authentication
  def self.controller_skips_authentication?(controller)
    # Cache the result to avoid repeated computation
    @auth_requirement_cache ||= {}
    return @auth_requirement_cache[controller.name] if @auth_requirement_cache.key?(controller.name)
    
    # Quick checks based on controller name
    if controller.name.include?('Admin')
      # Admin controllers always require authentication
      @auth_requirement_cache[controller.name] = false
      return false
    end
    
    if controller.name == 'PublicController'
      # PublicController explicitly skips authentication
      @auth_requirement_cache[controller.name] = true
      return true
    end
    
    # Inheritance-based checks
    if defined?(PublicController) && controller < PublicController
      # Inherits from PublicController, so skips authentication
      @auth_requirement_cache[controller.name] = true
      return true
    end
    
    if defined?(HubController) && controller < HubController
      # Inherits from HubController, which requires authentication
      @auth_requirement_cache[controller.name] = false
      return false
    end
    
    # Source code check for allow_unauthenticated_access
    result = false
    
    begin
      # Try to find a method to get the source location
      source_method = nil
      
      # First try index, then any instance method
      if controller.instance_methods(false).include?(:index)
        source_method = controller.instance_method(:index)
      elsif controller.instance_methods(false).any?
        source_method = controller.instance_method(controller.instance_methods(false).first)
      end
      
      # If we found a method with source location, check its content
      if source_method&.source_location
        source_file = source_method.source_location.first
        source_content = File.read(source_file)
        if source_content.match?(/\ballow_unauthenticated_access\b/)
          result = true
        end
      end
    rescue => e
      Rails.logger.debug "Error examining controller source for #{controller.name}: #{e.message}"
    end
    
    # Final check: Public namespace controllers (non-Admin, non-Authenticated)
    # typically skip authentication
    if !result && controller.name.start_with?('Public::') && !controller.name.match?(/Admin|Authenticated/)
      result = true
    end
    
    # Cache and return the result
    @auth_requirement_cache[controller.name] = result
    result
  end
  
  # Find all controllers that don't require authentication
  # Useful for debugging or auditing access controls
  # @return [Array<String>] list of controller paths that skip authentication
  def self.find_unauthenticated_controllers
    # Clear auth requirement cache to ensure fresh results
    @auth_requirement_cache = {}
    
    # Ensure all controllers are loaded
    Rails.application.eager_load!
    
    # Get all non-abstract controllers that inherit from ApplicationController
    controllers = ApplicationController.descendants.reject(&:abstract?)
    
    # Filter to only controllers that skip authentication and convert to permission paths
    controllers
      .select { |controller| controller_skips_authentication?(controller) }
      .map do |controller|
        namespace, controller_name = extract_namespace_and_controller(controller.name)
        namespace.present? ? "#{namespace}/#{controller_name}" : controller_name
      end
      .sort # Return sorted for consistency
  end
  
  # Helper method to extract namespace and controller name from a controller class name
  # This standardizes controller names for permission storage
  # @param controller_class_name [String] the full class name of a controller
  # @return [Array<String, String>] namespace and controller name components
  def self.extract_namespace_and_controller(controller_class_name)
    if controller_class_name.include?('::')
      # Handle namespaced controllers (e.g. Hub::Admin::UsersController)
      parts = controller_class_name.split('::')
      controller_name = parts.last.gsub('Controller', '').underscore
      
      # Multi-level namespace handling with proper path formatting
      if parts.size > 2
        # Join all parts except the last one (controller name part)
        namespace = parts[0...-1].map(&:underscore).join('/')
      else
        namespace = parts.first.underscore
      end
      
      [namespace, controller_name]
    else
      # Handle non-namespaced controllers (e.g. ApplicationController)
      controller_name = controller_class_name.gsub('Controller', '').underscore
      
      # Special handling for root namespace controllers (hub, club, etc.)
      if ROOT_CONTROLLERS.include?(controller_name.downcase)
        [controller_name.downcase, 'home']
      else
        [nil, controller_name]
      end
    end
  end
  
  # Process actions for a controller and create permission records as needed
  # @param controller [Class] the controller class to process
  # @param namespace [String] the namespace for the controller
  # @param controller_name [String] the name of the controller
  # @return [Integer] the number of new permissions created
  def self.process_controller_actions(controller, namespace, controller_name)
    # Track new permissions count
    new_permissions_count = 0
    
    # Find all valid controller actions (public instance methods)
    actions = controller.action_methods.reject { |action| action.blank? || action.start_with?('_') }
    
    # Process each action efficiently
    actions.each do |action|
      # Try to find existing permission or initialize a new one
      permission = Hub::Admin::Permission.find_or_initialize_by(
        namespace: namespace,
        controller: controller_name,
        action: action
      )
      
      # Set attributes and save if it's a new record
      unless permission.persisted?
        permission.status = 'active'
        permission.description = action_description(action)
        
        # Increment counter if save is successful
        new_permissions_count += 1 if permission.save
      end
    end
    
    # Return the number of new permissions created
    new_permissions_count
  end
  
  #=============================
  # CRUD Action Helpers
  #=============================
  
  # Returns all standard CRUD action names defined in the system
  # @return [Array<String>] list of standard CRUD action names
  def self.crud_actions
    CRUD_ACTIONS.keys
  end
  
  # Check if an action is one of the standard CRUD actions
  # @param action [String, Symbol] the action name to check
  # @return [Boolean] whether the action is a CRUD action
  def self.crud_action?(action)
    crud_actions.include?(action.to_s)
  end
  
  # Returns user-friendly descriptions for all CRUD actions
  # @return [Hash] mapping of CRUD actions to their descriptions
  def self.crud_descriptions
    CRUD_ACTIONS
  end
  
  # Gets a user-friendly description for any action
  # Uses predefined CRUD descriptions if available, or humanizes the action name
  # @param action [String, Symbol] the action to describe
  # @return [String] a user-friendly description of the action
  def self.action_description(action)
    CRUD_ACTIONS[action.to_s] || action.to_s.humanize
  end
  
  #=============================
  # Role Assignment Methods
  #=============================
  
  # Assigns all active permissions to the admin role
  # Creates the admin role if it doesn't exist
  # @return [Integer] the number of newly assigned permissions
  def self.assign_all_to_admin
    # Find or create admin role (case-insensitive search)
    admin_role = find_or_create_admin_role
    
    # Try to find a user to be the permission granter
    admin_user = Hub::Admin::User.first
    if admin_user.nil?
      Rails.logger.error "Error: No users found in the system to assign as permission granter"
      return 0
    end
    
    # Find all active permissions that need to be assigned
    permissions = Hub::Admin::Permission.where(status: 'active')
    
    # Track counts for logging
    assigned_count = 0
    exists_count = 0
    
    # Get IDs of permissions already assigned to avoid duplicates
    existing_permission_ids = admin_role.permission_assignments.pluck(:permission_id).to_set
    
    # Prepare batch of new assignments
    assignment_attributes = []
    current_time = Time.zone.now
    
    permissions.each do |permission|
      # Skip already assigned permissions
      if existing_permission_ids.include?(permission.id)
        exists_count += 1
        next
      end
      
      # Add to batch of assignments to create
      assignment_attributes << {
        role_id: admin_role.id,
        permission_id: permission.id,
        granted_by_id: admin_user.id,
        created_at: current_time,
        updated_at: current_time
      }
      
      assigned_count += 1
    end
    
    # Use Rails 8 batch insert for better performance
    if assignment_attributes.any?
      Hub::Admin::PermissionAssignment.insert_all(assignment_attributes)
      Rails.logger.info "Assigned #{assigned_count} new permissions to admin role (#{exists_count} already assigned)"
    else
      Rails.logger.info "No new permissions to assign to admin role (#{exists_count} already assigned)"
    end
    
    # Return the count of newly assigned permissions
    assigned_count
  end
  
  # Helper method to find or create the admin role
  # @return [Hub::Admin::Role] the admin role
  def self.find_or_create_admin_role
    admin_role = Hub::Admin::Role.where('LOWER(name) = ?', 'admin').first
    
    if admin_role.nil?
      admin_role = Hub::Admin::Role.create!(
        name: 'Admin',
        description: 'Administrator role with access to all system functions'
      )
      Rails.logger.info "Created Admin role"
    else
      Rails.logger.info "Found existing Admin role: #{admin_role.name}"
    end
    
    admin_role
  end
  
  # Returns actions that correspond to Pundit policy methods
  # Uses Rails 8 pattern for determining which controller actions have matching policy methods
  # @param filter_crud [Boolean] only include CRUD actions if true
  # @param include_all [Boolean] include all actions regardless of policy method existence
  # @return [Array<String>] list of action names
  def self.pundit_controllable_actions(filter_crud: false, include_all: false)
    # Standard Pundit policy methods that end with '?'
    standard_actions = %w[index show new create edit update destroy].freeze
    
    # For custom actions, we examine existing policies to find methods ending with '?'
    custom_actions = []
    
    if !filter_crud || include_all
      # Find all policy classes in the app
      Rails.application.eager_load!
      policy_classes = ApplicationPolicy.descendants rescue []
      
      # Extract any methods ending with '?' from all policies
      policy_classes.each do |policy_class|
        policy_methods = policy_class.instance_methods(false).map(&:to_s).select { |m| m.end_with?('?') }
        policy_methods.each do |method|
          # Remove the trailing '?' to get the controller action name
          action = method.chomp('?')
          custom_actions << action unless standard_actions.include?(action)
        end
      end
    end
    
    # Return the appropriate set based on filter_crud
    if filter_crud
      standard_actions
    elsif include_all
      (standard_actions + custom_actions).uniq
    else
      custom_actions.uniq
    end
  end
end
