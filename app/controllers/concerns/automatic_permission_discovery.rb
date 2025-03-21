# frozen_string_literal: true

# This concern adds automatic permission discovery capabilities to controllers
# When included in ApplicationController, it will automatically track controller usage
# and update permissions when new controllers and actions are added
module AutomaticPermissionDiscovery
  extend ActiveSupport::Concern

  included do
    # Track controller execution to discover permissions
    after_action :track_controller_action_execution, unless: :skip_permission_tracking?
  end

  class_methods do
    # Register a controller for automatic permission tracking
    def register_for_permission_tracking!
      @track_permissions = true
    end

    # Opt out of permission tracking
    def skip_permission_tracking!
      @skip_permissions = true
    end

    # Check if a controller has explicitly opted in for tracking
    def track_permissions?
      @track_permissions == true
    end

    # Check if a controller has opted out of tracking
    def skip_permissions?
      @skip_permissions == true
    end
  end

  private

  # Should we skip tracking permissions for this controller action?
  def skip_permission_tracking?
    # Skip if the controller has explicitly opted out
    return true if self.class.skip_permissions?
    
    # Skip tracking in development mode when explicitly configured
    return true if Rails.env.development? && !Rails.configuration.track_permissions_in_development
    
    # Skip for public controllers and authentication controllers
    return true if skip_authorization?
    
    # Skip for system controllers that don't need granular permissions
    self.class.name.include?('Admin::SystemController') ||
    controller_path.include?('admin/system')
  end

  # Track controller action execution for permission discovery
  def track_controller_action_execution
    # Extract controller and action information
    controller_data = extract_controller_data
    
    # Queue a job to ensure permissions exist for this controller and action
    Hub::Admin::ProcessNewControllerActionJob.perform_later(
      controller_data[:namespace],
      controller_data[:controller],
      controller_data[:action],
      controller_data[:description]
    )
  end

  # Extract all relevant controller data for permission tracking
  def extract_controller_data
    # Parse namespace and controller from controller_path
    if controller_path.include?('/')
      namespace = controller_path.split('/')[0..-2].join('/')
      controller = controller_path.split('/').last
    else
      namespace = ''
      controller = controller_path
    end

    # Generate description based on action name and controller
    description = generate_action_description(namespace, controller, action_name)

    {
      namespace: namespace,
      controller: controller,
      action: action_name,
      description: description
    }
  end

  # Generate a human-readable description for an action
  def generate_action_description(namespace, controller, action)
    crud_actions = {
      'index' => 'View list of records in',
      'show' => 'View details of a record in',
      'new' => 'Access new record form in',
      'create' => 'Create a new record in',
      'edit' => 'Access edit record form in',
      'update' => 'Update an existing record in',
      'destroy' => 'Delete a record in'
    }

    controller_name = controller.humanize
    namespace_prefix = namespace.present? ? "#{namespace}/" : ''

    if crud_actions.key?(action)
      "#{crud_actions[action]} #{namespace_prefix}#{controller_name}"
    else
      "#{action.humanize} in #{namespace_prefix}#{controller_name}"
    end
  end
end
