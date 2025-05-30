# frozen_string_literal: true

# This module extends Pundit with helper methods specific to our application
# It provides standardized methods for authorization checks consistent with Pundit conventions
module PunditHelper
  extend ActiveSupport::Concern

  included do
    include Pundit::Authorization
    
    # Make helpers available to views
    helper_method :allowed_to?, :user_is_admin? if respond_to?(:helper_method)
    
    # Handle Pundit authorization errors
    rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized
  end

  # Check if current user can access a specific resource (safer version of policy(record).action?)
  # This provides a standard interface for controllers and views
  # @example allowed_to?(:update, @post)
  # @example allowed_to?(:create, Post)
  # @example allowed_to?(:index, { namespace: 'hub/admin', controller: 'users' })
  # @example allowed_to?(:manage, { namespace: 'hub/admin', controller: 'tubers', farm: @farm })
  def allowed_to?(action, record_or_options)
    return false unless Current.user
    
    begin
      # Handle namespace-style hash options with optional farm context
      if record_or_options.is_a?(Hash) && record_or_options[:namespace].present? && record_or_options[:controller].present?
        namespace = record_or_options[:namespace]
        controller = record_or_options[:controller]
        farm = record_or_options[:farm]
        
        return Current.user.can?(action, namespace, controller, farm: farm)
      end
      
      # Handle standard Pundit policy checks
      action_string = action.to_s.end_with?('?') ? action.to_s : "#{action}?"
      policy = policy(record_or_options)
      policy.public_send(action_string)
    rescue Pundit::NotAuthorizedError, NoMethodError
      false
    end
  end

  # Shorthand method to check if user is admin
  def user_is_admin?
    Current.user&.admin? == true
  end

  # Handle authorization failures with proper redirect and flash message
  def user_not_authorized(exception)
    policy_name = exception.policy.class.to_s.underscore
    action = exception.query.to_s.delete('?')
    
    flash[:alert] = t('pundit.not_authorized', 
                       action: action.humanize.downcase, 
                       policy: policy_name.humanize.downcase,
                       default: 'You are not authorized to perform this action.')
    
    redirect_back(fallback_location: main_app.root_path, status: :forbidden)
  end

  # Helper for namespace-based authorization using standard Pundit patterns
  # Use this method when you need to authorize access to a specific namespace/controller
  # rather than authorizing a specific model instance
  # @param namespace [String] the namespace to authorize
  # @param controller [String] the controller to authorize
  # @param action [String, nil] the action to authorize (defaults to current action_name)
  # @param farm [Hub::Admin::Farm, nil] optional farm to check farm-specific permissions for
  # @raise [Pundit::NotAuthorizedError] if user is not authorized
  # @return [true] if authorized
  def authorize_namespace(namespace, controller, action = nil, farm: nil)
    action ||= action_name
    authorized = AuthorizationService.user_has_permission?(Current.user, namespace, controller, action, farm: farm)
    
    unless authorized
      # If not authorized, raise the same error Pundit would, for consistent error handling
      policy = NamespacePolicy.new(Current.user, { namespace: namespace, controller: controller, action: action, farm: farm })
      raise Pundit::NotAuthorizedError.new(query: action, policy: policy, record: policy.record)
    end
    
    true
  end

  # Helper for scoping collections based on namespace permissions
  # Useful for index actions to filter records based on user permissions
  # @param scope_class [Class] the class to scope
  # @param namespace [String, nil] the namespace (defaults to controller namespace)
  # @param controller [String, nil] the controller name (defaults to current controller_name)
  # @param farm [Hub::Admin::Farm, nil] optional farm to check farm-specific permissions for
  # @return [ActiveRecord::Relation] the scoped records
  def namespace_scope(scope_class, namespace: nil, controller: nil, farm: nil)
    namespace ||= controller_path.split('/')[0..1].join('/')
    controller ||= controller_name
    
    # If admin user, return all records
    return scope_class.all if Current.user&.admin?
    
    # If user has index permission for this namespace/controller, return all records
    # Pass the farm context to check farm-specific permissions when appropriate
    if AuthorizationService.user_has_permission?(Current.user, namespace, controller, 'index', farm: farm)
      scope_class.all
    else
      # Otherwise return an empty relation
      scope_class.none
    end
  end
end
