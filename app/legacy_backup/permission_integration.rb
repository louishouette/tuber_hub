# frozen_string_literal: true

# DEPRECATED: This module is being phased out in favor of PermissionPolicyConcern.
# This module now acts as a proxy to maintain backward compatibility.
# New policies should include PermissionPolicyConcern instead.
module PermissionIntegration
  extend ActiveSupport::Concern
  
  included do
    ActiveSupport::Deprecation.warn(
      "PermissionIntegration is deprecated and will be removed in a future version. " +
      "Use PermissionPolicyConcern instead."
    )
  end
  
  # Check if the current user has permission for the given action
  # This automatically maps the calling method (e.g., update?) to a database permission
  # @param namespace [String, nil] controller namespace, will be extracted from record if nil
  # @param controller [String, nil] controller name, will be extracted from record if nil
  # @param custom_action [String, nil] custom action name, will be extracted from caller if nil
  # @param farm [Hub::Admin::Farm, nil] optional farm to check farm-specific permissions for
  # @return [Boolean] whether the user has permission
  def permission_check(namespace: nil, controller: nil, custom_action: nil, farm: nil)
    # Determine the correct action, namespace, controller, and farm
    action = custom_action || extract_action_from_caller
    namespace ||= extract_namespace_from_record
    controller ||= extract_controller_from_record
    farm ||= extract_farm_from_record
    
    # Delegate to the centralized authorization service
    AuthorizationService.user_has_permission?(user, namespace, controller, action, farm: farm)
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
  
  # Try to extract farm from the record if it's a hash with farm key
  def extract_farm_from_record
    if record.is_a?(Hash) && record[:farm]
      record[:farm]
    elsif record.respond_to?(:farm)
      # If the record has a farm association, use that
      record.farm
    elsif record.is_a?(Hash) && record[:farm_id] && defined?(Hub::Admin::Farm)
      # If we have a farm_id but not a farm object, try to load it
      Hub::Admin::Farm.find_by(id: record[:farm_id])
    end
  end
  
  # Extract namespace from a class name
  def namespace_from_class_name(class_name)
    parts = class_name.underscore.split('/')
    parts.size > 1 ? parts[0..-2].join('/') : ''
  end
end
