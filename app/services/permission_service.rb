# frozen_string_literal: true

# Service class for handling database-driven permissions and integrating with Pundit policies
# Manages permission discovery, assignment, and access control throughout the application
class PermissionService
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
  
  #===========================================================================
  # Permission Querying Methods
  #===========================================================================
  
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
    Rails.cache.fetch('grouped_permissions', expires_in: 15.minutes) do
      active_permissions(exclude_system: exclude_system)
        .group_by(&:namespace)
        .transform_values { |perms| perms.group_by(&:controller) }
    end
  end
  
  # Checks if a user has a specific permission based on their roles
  # Fast-paths for admin users and unauthenticated access
  # This is the central method for all permission checks in the application.
  # @param user [Hub::Admin::User, nil] the user to check permissions for
  # @param namespace [String] controller namespace
  # @param controller [String] controller name
  # @param action [String] action name
  # @param use_preloaded [Boolean] whether to use preloaded permissions if available
  # @return [Boolean] whether the user has permission
  def self.user_has_permission?(user, namespace, controller, action, use_preloaded: false)
    # Fast path for admin users and nil users
    return true if user&.admin? # Admin users can do everything
    return false unless user    # No user, no permissions
    
    # Format parameters consistently
    namespace = namespace.to_s
    controller = controller.to_s
    action = action.to_s
    
    # Try to use preloaded permissions if requested and available
    if use_preloaded && user.instance_variable_defined?(:@preloaded_permissions)
      permission_key = "#{namespace}:#{controller}:#{action}"
      return user.instance_variable_get(:@preloaded_permissions).include?(permission_key)
    end
    
    # Generate a unique cache key for this permission check
    cache_key = "user_#{user.id}_permission_#{namespace}:#{controller}:#{action}"
    
    Rails.cache.fetch(cache_key, expires_in: 1.hour) do
      # Get the user's role IDs efficiently
      role_ids = user.roles.pluck(:id)
      return false if role_ids.empty?
      
      # Query whether any of the user's roles have this permission
      # Account for both unlimited and non-expired permissions
      Hub::Admin::Permission
        .joins(:permission_assignments)
        .where(status: 'active')
        .where(namespace: namespace, controller: controller, action: action)
        .where(hub_admin_permission_assignments: { role_id: role_ids })
        .where(
          'hub_admin_permission_assignments.expires_at IS NULL OR ' 
          'hub_admin_permission_assignments.expires_at > ?', 
          Time.zone.now
        )
        .exists?
    end
  end
  
  # Preloads all permissions for a user to avoid N+1 queries
  # @param user [Hub::Admin::User] the user to preload permissions for
  # @param namespaces [Array<String>] optional array of namespaces to limit preloading
  # @return [Array<String>] array of permission strings in format "namespace:controller:action"
  def self.preload_user_permissions(user, namespaces: nil)
    return [] unless user && !user.admin?
    
    # Get user's role IDs
    role_ids = user.roles.pluck(:id)
    return [] if role_ids.empty?
    
    # Build the query for the user's permissions, optimized with proper indices
    permissions_query = Hub::Admin::Permission
      .select(:namespace, :controller, :action)
      .distinct
      .joins(:permission_assignments)
      .where(status: 'active')
      .where(hub_admin_permission_assignments: { role_id: role_ids })
      .where(
        'hub_admin_permission_assignments.expires_at IS NULL OR ' 
        'hub_admin_permission_assignments.expires_at > ?', 
        Time.zone.now
      )
    
    # Add namespace filter if specified
    permissions_query = permissions_query.where(namespace: namespaces) if namespaces.present?
    
    # Execute query and format results as permission strings
    permission_strings = permissions_query.map do |p|
      "#{p.namespace}:#{p.controller}:#{p.action}"
    end
    
    # Store on user instance for later use
    user.instance_variable_set(:@preloaded_permissions, permission_strings)
    
    # Return the permission strings
    permission_strings
  end
  
  #===========================================================================
  # Permission Management Methods
  #===========================================================================
  
  # Refreshes the permissions by scanning controllers and clearing cache
  # @return [Boolean] whether the operation succeeded
  def self.refresh_permissions
    # Run the permissions discovery
    permission_count = discover_permissions
    
    # Clear all permission-related caches systematically
    clear_all_permission_caches
    
    # Log successful refresh
    Rails.logger.info("Permission refresh completed: #{permission_count} active permissions")
    true
  rescue => e
    # Log failure with detailed error information
    Rails.logger.error("Permission refresh failed: #{e.message}\n#{e.backtrace.join('\n')}")
    false
  end
  
  # Clears all permission-related caches
  # @return [void]
  def self.clear_all_permission_caches
    # Clear the general permissions cache
    Rails.cache.delete('grouped_permissions')
    
    # Clear all user permission caches
    Rails.cache.delete_matched("user_*_permission_*")
  end
  
  # Clears permission caches for a specific user
  # @param user [Hub::Admin::User] the user whose caches to clear
  # @return [void]
  def self.clear_user_permission_caches(user)
    return unless user&.id
    
    # Clear all permissions for this specific user
    Rails.cache.delete_matched("user_#{user.id}_permission_*")
  end
  
  # Clears permission caches for a specific permission
  # @param namespace [String] namespace of the permission
  # @param controller [String] controller of the permission
  # @param action [String] action of the permission
  # @return [void]
  def self.clear_permission_caches(namespace, controller, action)
    # Create a pattern to match any user's cache for this permission
    cache_pattern = "user_*_permission_#{namespace}:#{controller}:#{action}"
    
    # Delete all matching caches
    Rails.cache.delete_matched(cache_pattern)
  end

  # Discovers all controller actions and creates permissions records
  # @return [Integer] the count of active permissions after discovery
  def self.discover_permissions
    # Ensure all controllers are loaded
    Rails.application.eager_load!
    
    # Track statistics for logging
    processed_count = 0
    new_count = 0
    
    # Get application controllers that require authentication
    app_authenticated_controllers.each do |controller|
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
  
  # Get all application controllers that require authentication
  # @return [Array<Class>] list of controller classes that require authentication
  def self.app_authenticated_controllers
    # Get all application controllers, skipping abstract ones
    all_controllers = ApplicationController.descendants.reject(&:abstract?)
    
    # Filter for controllers defined in the app and requiring authentication
    all_controllers.select do |controller|
      controller_from_app?(controller) && !controller_skips_authentication?(controller)
    end
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
    
    result = determine_authentication_requirement(controller)
    
    # Cache and return the result
    @auth_requirement_cache[controller.name] = result
    result
  end
  
  # Determine if a controller requires authentication based on various rules
  # @param controller [Class] the controller class to check
  # @return [Boolean] whether the controller skips authentication
  def self.determine_authentication_requirement(controller)
    # Quick checks based on controller name
    return false if controller.name.include?('Admin') # Admin controllers always require authentication
    return true if controller.name == 'PublicController' # PublicController explicitly skips authentication
    
    # Inheritance-based checks
    return true if defined?(PublicController) && controller < PublicController
    return false if defined?(HubController) && controller < HubController
    
    # Source code check for allow_unauthenticated_access
    begin
      source_content = get_controller_source_content(controller)
      return true if source_content && source_content.match?(/\ballow_unauthenticated_access\b/)
    rescue => e
      Rails.logger.debug "Error examining controller source for #{controller.name}: #{e.message}"
    end
    
    # Final check: Public namespace controllers (non-Admin, non-Authenticated)
    # typically skip authentication
    return true if controller.name.start_with?('Public::') && !controller.name.match?(/Admin|Authenticated/)
    
    # Default to requiring authentication
    false
  end
  
  # Get the source content of a controller
  # @param controller [Class] the controller class to check
  # @return [String, nil] the source content of the controller or nil if not found
  def self.get_controller_source_content(controller)
    # Try to find a method to get the source location
    source_method = nil
    
    # First try index, then any instance method
    if controller.instance_methods(false).include?(:index)
      source_method = controller.instance_method(:index)
    elsif controller.instance_methods(false).any?
      source_method = controller.instance_method(controller.instance_methods(false).first)
    end
    
    # If we found a method with source location, return its content
    if source_method&.source_location
      source_file = source_method.source_location.first
      File.read(source_file)
    end
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
    
    # Filter to only app controllers that skip authentication and convert to permission paths
    controllers
      .select { |controller| controller_from_app?(controller) && controller_skips_authentication?(controller) }
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
      extract_namespaced_controller(controller_class_name)
    else
      extract_non_namespaced_controller(controller_class_name)
    end
  end
  
  # Extract namespace and controller from a namespaced controller class name
  # @param controller_class_name [String] the full class name of a namespaced controller
  # @return [Array<String, String>] namespace and controller name components
  def self.extract_namespaced_controller(controller_class_name)
    # Handle namespaced controllers (e.g. Hub::Admin::UsersController)
    parts = controller_class_name.split('::')
    controller_name = parts.last.gsub('Controller', '').underscore
    
    # Multi-level namespace handling with proper path formatting
    namespace = if parts.size > 2
      # Join all parts except the last one (controller name part)
      parts[0...-1].map(&:underscore).join('/')
    else
      parts.first.underscore
    end
    
    [namespace, controller_name]
  end
  
  # Extract namespace and controller from a non-namespaced controller class name
  # @param controller_class_name [String] the full class name of a non-namespaced controller
  # @return [Array<String, String>] namespace and controller name components
  def self.extract_non_namespaced_controller(controller_class_name)
    controller_name = controller_class_name.gsub('Controller', '').underscore
    
    # Special handling for root namespace controllers
    if root_controllers.include?(controller_name.downcase)
      [controller_name.downcase, 'home']
    else
      [nil, controller_name]
    end
  end
  


  # Dynamically discovers main namespaces from application controllers
  # Only includes namespaces from controllers defined within the app/ directory
  # @return [Array<String>] list of unique namespaces in the application
  # @note This is cached for performance
  def self.main_namespaces
    Rails.cache.fetch('permission_service:main_namespaces', expires_in: 1.hour) do
      # Ensure all controllers are loaded
      Rails.application.eager_load!
      
      # Get all app controllers
      app_controllers = ApplicationController.descendants
        .reject(&:abstract?)
        .select { |controller| controller_from_app?(controller) }
      
      # Extract namespaces from app controllers
      extract_namespaces_from_controllers(app_controllers)
    end
  end
  
  # Extracts unique namespaces from a list of controllers
  # @param controllers [Array<Class>] list of controller classes
  # @return [Array<String>] sorted list of unique namespaces
  def self.extract_namespaces_from_controllers(controllers)
    namespaces = Set.new
    
    controllers.each do |controller|
      namespace, _controller_name = extract_namespace_and_controller(controller.name)
      next unless namespace.present?
      
      # For multi-level namespaces, add each level
      parts = namespace.split('/')
      (1..parts.size).each do |depth|
        namespaces << parts[0...depth].join('/')
      end
    end
    
    # Convert to sorted array and freeze
    namespaces.to_a.sort.freeze
  end
  
  # Dynamically discovers root controllers from the application
  # These are controllers that serve as home controllers for namespaces
  # Only includes controllers defined within the app/ directory
  # @return [Array<String>] list of root controllers
  # @note This is cached for performance
  def self.root_controllers
    Rails.cache.fetch('permission_service:root_controllers', expires_in: 1.hour) do
      # Ensure all controllers are loaded
      Rails.application.eager_load!
      
      # Get app controllers
      app_controllers = ApplicationController.descendants
        .reject(&:abstract?)
        .select { |controller| controller_from_app?(controller) }
      
      # Find root controller names
      find_root_controller_names(app_controllers)
    end
  end
  
  # Find root controller names from a list of controllers
  # @param controllers [Array<Class>] list of controller classes
  # @return [Array<String>] list of root controller names
  def self.find_root_controller_names(controllers)
    root_names = Set.new
    
    controllers.each do |controller|
      namespace, controller_name = extract_namespace_and_controller(controller.name)
      
      # If this is a single-level namespace controller (e.g., HubController)
      if namespace.present? && !namespace.include?('/') && controller_name == 'home'
        root_names << namespace
      end
    end
    
    # Convert to array and freeze
    root_names.to_a.freeze
  end
  
  # Process actions for a controller and create permission records as needed
  # @param controller [Class] the controller class to process
  # @param namespace [String] the namespace for the controller
  # @param controller_name [String] the name of the controller
  # @return [Integer] the number of new permissions created
  def self.process_controller_actions(controller, namespace, controller_name)
    # Track new permissions count
    new_permissions_count = 0
    
    # Get valid controller actions
    actions = get_valid_controller_actions(controller)
    
    # Skip further processing if no actions found
    return 0 if actions.empty?
    
    # Process each action and create/update permission records
    actions.each do |action|
      new_permissions_count += create_or_update_permission(namespace, controller_name, action)
    end
    
    # Return the number of new permissions created
    new_permissions_count
  end
  
  # Get valid controller actions for permission processing
  # @param controller [Class] the controller class to process
  # @return [Array<String>] list of valid action names
  def self.get_valid_controller_actions(controller)
    controller.action_methods.reject { |action| action.blank? || action.start_with?('_') }
  end
  
  # Create or update a permission record for a specific controller action
  # @param namespace [String] the namespace for the controller
  # @param controller_name [String] the name of the controller
  # @param action [String] the action name
  # @return [Integer] 1 if a new permission was created, 0 otherwise
  def self.create_or_update_permission(namespace, controller_name, action)
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
      
      # Return 1 if save is successful, 0 otherwise
      permission.save ? 1 : 0
    else
      0 # No new permission created
    end
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
  
  #===========================================================================
  # Controller Helper Methods
  #===========================================================================
  
  # Determines if a controller is defined within the application (not from gems or Rails)
  # @param controller [Class] the controller class to check
  # @return [Boolean] whether the controller is defined in the app/ directory
  def self.controller_from_app?(controller)
    begin
      # Try to get the source location using action_methods method first
      source_location = controller.instance_method(:action_methods).source_location&.first
      
      # If we can't determine location, try another instance method
      if source_location.nil? && controller.instance_methods(false).any?
        method_name = controller.instance_methods(false).first
        source_location = controller.instance_method(method_name).source_location&.first
      end
      
      # Check if source location is under app/
      source_location && source_location.start_with?(APP_ROOT_PATH)
    rescue => e
      Rails.logger.debug("Error determining controller source for #{controller.name}: #{e.message}")
      false # Skip if we can't determine
    end
  end
  
  #===========================================================================
  # Policy Integration Methods
  #===========================================================================
  
  # Returns actions that correspond to Pundit policy methods
  # Uses Rails 8 pattern for determining which controller actions have matching policy methods
  # @param filter_crud [Boolean] only include CRUD actions if true
  # @param include_all [Boolean] include all actions regardless of policy method existence
  # @return [Array<String>] list of action names
  def self.pundit_controllable_actions(filter_crud: false, include_all: false)
    # Get standard and custom actions
    standard_actions = standard_pundit_actions
    custom_actions = []
    
    # Collect custom policy actions if needed
    if !filter_crud || include_all
      custom_actions = find_custom_policy_actions(standard_actions)
    end
    
    # Return the appropriate set based on parameters
    if filter_crud
      standard_actions
    elsif include_all
      (standard_actions + custom_actions).uniq
    else
      custom_actions.uniq
    end
  end
  
  # Returns the standard Pundit policy actions (common CRUD methods)
  # @return [Array<String>] list of standard action names
  def self.standard_pundit_actions
    %w[index show new create edit update destroy].freeze
  end
  
  # Finds all custom policy methods from ApplicationPolicy descendants
  # @param standard_actions [Array<String>] list of standard actions to exclude
  # @return [Array<String>] list of custom action names from policy classes
  def self.find_custom_policy_actions(standard_actions)
    custom_actions = []
    
    # Find all policy classes in the app
    Rails.application.eager_load!
    policy_classes = ApplicationPolicy.descendants rescue []
    
    # Extract custom action methods from policy classes
    policy_classes.each do |policy_class|
      extract_custom_policy_actions(policy_class, standard_actions, custom_actions)
    end
    
    custom_actions
  end
  
  # Extracts custom action methods from a policy class
  # @param policy_class [Class] the policy class to examine
  # @param standard_actions [Array<String>] list of standard actions to exclude
  # @param custom_actions [Array<String>] array to collect custom actions into
  # @return [void]
  def self.extract_custom_policy_actions(policy_class, standard_actions, custom_actions)
    policy_methods = policy_class.instance_methods(false).map(&:to_s).select { |m| m.end_with?('?') }
    
    policy_methods.each do |method|
      # Remove the trailing '?' to get the controller action name
      action = method.chomp('?')
      custom_actions << action unless standard_actions.include?(action)
    end
  end
end
