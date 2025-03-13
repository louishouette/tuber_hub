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
  def allowed_to?(action, record)
    return false unless Current.user
    
    begin
      # Handle standard Pundit policy checks
      action_string = action.to_s.end_with?('?') ? action.to_s : "#{action}?"
      policy = policy(record)
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
  def authorize_namespace(namespace, controller, action = nil)
    namespace_params = {
      namespace: namespace,
      controller: controller,
      action: action || action_name
    }
    
    # Use standard authorize method with appropriate action
    authorize namespace_params, policy_class: NamespacePolicy
  end

  # Helper for scoping collections based on namespace permissions
  # Useful for index actions to filter records based on user permissions
  def namespace_scope(scope_class, namespace: nil, controller: nil)
    namespace ||= controller_path.split('/')[0..1].join('/')
    controller ||= controller_name
    
    # Create policy scope with namespace context
    policy_scope(scope_class, policy_scope_class: NamespacePolicy::Scope, namespace: namespace, controller: controller)
  end
end
