# frozen_string_literal: true

# This concern provides permission-based authorization for Pundit policies
# It integrates with the authorization service to provide consistent permission checking
module PermissionPolicyConcern
  extend ActiveSupport::Concern

  included do
    # Override the default method_missing to handle dynamic permission checks
    def method_missing(method_name, *args, &block)
      # Check if the method is an action permission check (ends with a ?)
      if method_name.to_s.end_with?('?')
        # Extract the action name (remove the ? at the end)
        action_name = method_name.to_s.chomp('?')
        
        # Get the policy class name and extract the namespace and controller
        policy_class_name = self.class.name
        namespace, controller = namespace_and_controller_from_policy(policy_class_name)
        
        # Check if the user has permission for this namespace/controller/action
        return authorize_action(namespace, controller, action_name)
      end
      
      # If not a permission check, use normal method_missing behavior
      super
    end
    
    # Make respond_to? aware of our dynamic methods
    def respond_to_missing?(method_name, include_private = false)
      method_name.to_s.end_with?('?') || super
    end
  end
  
  # Authorize an action based on permissions
  # @param namespace [String] the namespace
  # @param controller [String] the controller
  # @param action [String] the action
  # @return [Boolean] whether the user is authorized
  def authorize_action(namespace, controller, action)
    # Get the farm context if applicable
    farm = extract_farm_from_record
    
    # Check admin status first (admins can do everything)
    return true if Current.user.admin?
    
    # Check for specific permission through the authorization service
    AuthorizationService.user_has_permission?(Current.user, namespace, controller, action, farm: farm)
  end
  
  # Extract namespace and controller from a policy class name
  # @param policy_class_name [String] the policy class name
  # @return [Array<String, String>] namespace and controller
  def namespace_and_controller_from_policy(policy_class_name)
    # Remove the 'Policy' suffix and convert to underscored format
    controller_path = policy_class_name.chomp('Policy').underscore
    
    if controller_path.include?('/')
      # Extract namespace and controller name from path
      namespace = controller_path.split('/')[0..-2].join('/')
      controller = controller_path.split('/').last
    else
      # No namespace
      namespace = ''
      controller = controller_path
    end
    
    [namespace, controller]
  end
  
  # Try to extract farm from the record if relevant
  # @return [Hub::Admin::Farm, nil] the farm or nil
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
end
