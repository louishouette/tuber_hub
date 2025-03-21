# frozen_string_literal: true

# This module provides a bridge between the application's database-driven permission system
# and Pundit's policy-based authorization. It allows Pundit policies to leverage the existing
# roles and permissions model.
module PermissionIntegration
  extend ActiveSupport::Concern
  
  # Check if the current user has permission for the given action
  # This automatically maps the calling method (e.g., update?) to a database permission
  # @param namespace [String, nil] controller namespace, will be extracted from record if nil
  # @param controller [String, nil] controller name, will be extracted from record if nil
  # @param custom_action [String, nil] custom action name, will be extracted from caller if nil
  # @return [Boolean] whether the user has permission
  def permission_check(namespace: nil, controller: nil, custom_action: nil)
    # Determine the correct action, namespace, and controller
    action = custom_action || extract_action_from_caller
    namespace ||= extract_namespace_from_record
    controller ||= extract_controller_from_record
    
    # Delegate to the centralized permission service
    PermissionService.user_has_permission?(user, namespace, controller, action)
  end
  
  private
  
  # Extract the action name from the calling method (removing ? suffix)
  def extract_action_from_caller
    # Get the name of the method that called permission_check
    caller_method = caller_locations(1,1)[0].label
    # Remove the question mark for predicate methods
    caller_method.to_s.chomp('?')
  end
  
  # Try to extract namespace from the record if it's a hash with namespace key
  def extract_namespace_from_record
    if record.is_a?(Hash) && record[:namespace]
      record[:namespace]
    else
      # Default to controller_path from record's class if possible
      namespace_from_class_name(record.class.name) if record.respond_to?(:class)
    end
  end
  
  # Try to extract controller from the record if it's a hash with controller key
  def extract_controller_from_record
    if record.is_a?(Hash) && record[:controller]
      record[:controller]
    else
      # Default to table_name from record's class if possible
      record.class.table_name.split('_').last if record.respond_to?(:class) && record.class.respond_to?(:table_name)
    end
  end
  
  # Extract namespace from a class name
  def namespace_from_class_name(class_name)
    parts = class_name.underscore.split('/')
    parts.size > 1 ? parts[0..-2].join('/') : ''
  end
end
