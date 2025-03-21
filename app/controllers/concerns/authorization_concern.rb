# frozen_string_literal: true

# This concern provides controller-level authorization functionality
# It integrates with Pundit and the AuthorizationService to provide consistent permission checking
module AuthorizationConcern
  extend ActiveSupport::Concern

  included do
    include Pundit::Authorization
    
    # Set up rescue handlers for authorization failures
    rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized
    
    # Define helper method for the current namespace
    helper_method :current_namespace
  end
  
  # Check if the current user has permission for a specific action
  # @param namespace [String] the namespace
  # @param controller [String] the controller name
  # @param action [String] the action name
  # @param use_preloaded [Boolean] whether to use preloaded permissions
  # @param farm [Hub::Admin::Farm, nil] optional farm context
  # @return [Boolean] whether the user has permission
  def user_can?(action, controller = controller_name, namespace = current_namespace, use_preloaded: false, farm: nil)
    # Skip permission check for admins
    return true if Current.user&.admin?
    
    # Check permission through the authorization service
    AuthorizationService.user_has_permission?(
      Current.user,
      namespace,
      controller,
      action,
      use_preloaded: use_preloaded,
      farm: farm
    )
  end
  
  # Authorize action based on namespace/controller/action permission
  # Similar to Pundit's authorize but uses our permission system directly
  # @param namespace [String] the namespace
  # @param controller [String] the controller name
  # @param action [String] the action name
  # @param farm [Hub::Admin::Farm, nil] optional farm context
  # @raise [Pundit::NotAuthorizedError] if the user isn't authorized
  # @return [Boolean] true if authorized
  def authorize_action!(action = action_name, controller = controller_name, namespace = current_namespace, farm: nil)
    return true if Current.user&.admin?
    
    unless user_can?(action, controller, namespace, farm: farm)
      raise Pundit::NotAuthorizedError, "Not allowed to perform #{action} on #{controller} in #{namespace}"
    end
    
    true
  end
  
  # Get the current controller namespace
  # @return [String] the namespace
  def current_namespace
    @current_namespace ||= begin
      # Extract from controller path
      if self.class.controller_path.include?('/')
        self.class.controller_path.split('/')[0..-2].join('/')
      else
        ''
      end
    end
  end
  
  # Helper to preload permissions for the current user in specified namespaces
  # @param namespaces [Array<String>] the namespaces to preload permissions for
  # @param farm [Hub::Admin::Farm, nil] optional farm context
  # @return [Array<String>] the preloaded permission strings
  def preload_user_permissions(namespaces = [current_namespace], farm: nil)
    return [] unless Current.user && !Current.user.admin?
    
    AuthorizationService.preload_user_permissions(
      Current.user,
      namespaces: namespaces,
      farm: farm
    )
  end
  
  private
  
  # Handler for authorization failures
  # @param exception [Pundit::NotAuthorizedError] the authorization error
  def user_not_authorized(exception)
    policy_name = exception.policy.class.to_s.underscore
    error_message = I18n.t(
      "pundit.#{policy_name}.#{exception.query}",
      default: 'You are not authorized to perform this action.'
    )
    
    respond_to do |format|
      format.html do
        flash[:alert] = error_message
        redirect_to(request.referer || root_path)
      end
      format.json { render json: { error: error_message }, status: :forbidden }
      format.js { render json: { error: error_message }, status: :forbidden }
    end
  end
end
