class ApplicationController < ActionController::Base
  include Authentication
  include Pundit::Authorization
  include PunditHelper
  include CurrentFarm
  include AutomaticPermissionDiscovery

  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Ensure authorization is applied to all actions except specified ones
  after_action :verify_authorized, except: [:index], unless: :skip_authorization?
  after_action :verify_policy_scoped, only: [:index], unless: :skip_policy_scope_check?

  # Globally rescue from Pundit::NotAuthorizedError
  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  private

  def user_not_authorized(exception = nil)
    # Extract policy and query information for better error messages
    policy_name = exception&.policy&.class&.name || 'Unknown'
    query = exception&.query || 'perform this action'
    controller_action = "#{controller_name}##{action_name}"
    
    # Log the authorization failure for monitoring and debugging
    log_authorization_failure(policy_name, query, controller_action)
    
    # Prepare user-friendly error message with context
    error_message = generate_authorization_error_message(query)
    
    respond_to do |format|
      format.html do
        flash[:alert] = error_message
        redirect_to(request.referrer || root_path)
      end
      format.json { render json: { error: error_message, detail: policy_name }, status: :forbidden }
      format.js { head :forbidden }
      format.turbo_stream { render turbo_stream: turbo_stream.replace('flash', partial: 'shared/flash') }
    end
  end
  
  # Generate a user-friendly error message based on the authorization context
  def generate_authorization_error_message(query)
    # Customize error message based on the action being attempted
    case query.to_s
    when 'index?'
      'You do not have permission to view this list.'
    when 'show?'
      'You do not have permission to view this record.'
    when 'create?', 'new?'
      'You do not have permission to create new records here.'
    when 'update?', 'edit?'
      'You do not have permission to modify this record.'
    when 'destroy?'
      'You do not have permission to delete this record.'
    else
      # Farm-specific message if in a farm context
      if Current.farm.present?
        "You are not authorized to #{query.to_s.delete('?').humanize.downcase} in this farm."
      else
        "You are not authorized to #{query.to_s.delete('?').humanize.downcase}."
      end
    end
  end
  
  # Log authorization failures for monitoring and auditing
  def log_authorization_failure(policy_name, query, controller_action)
    user_info = Current.user ? "User ID: #{Current.user.id}, Email: #{Current.user.email}" : 'Unauthenticated user'
    farm_context = Current.farm ? "Farm ID: #{Current.farm.id}, Name: #{Current.farm.name}" : 'No farm context'
    
    Rails.logger.warn("Authorization Failure: #{user_info} | #{farm_context} | Policy: #{policy_name} | Query: #{query} | Controller Action: #{controller_action}")
    
    # Log to an audit trail if available
    Authentication.log_authorization_failure(
      user: Current.user,
      policy_name: policy_name,
      query: query,
      controller_action: controller_action,
      farm: Current.farm
    ) if defined?(Authentication.log_authorization_failure)
  end

  # Make current_user available to policies
  def pundit_user
    Current.user
  end
  
  # Methods for skipping policy checks in certain controller actions
  def skip_authorization?
    devise_controller? || 
    is_public_controller? || 
    is_authentication_controller?
  end
  
  def skip_policy_scope?
    devise_controller? || 
    is_public_controller? || 
    is_authentication_controller?
  end
  
  # Check if the current controller is exempt from Pundit checks
  def is_public_controller?
    controller_path == 'home' || # Main home page
    controller_path == 'static' || # Static pages like terms, about, etc.
    controller_path.start_with?('public/') || # All controllers in the Public namespace
    controller_path == 'hub/home' # Hub dashboard/home page
  end
  
  # Check if this is an authentication controller
  def is_authentication_controller?
    self.class.name == 'SessionsController' ||
    controller_path == 'sessions' ||
    controller_path == 'passwords' ||
    controller_path == 'registrations'
  end
  
  # Checks if we should skip policy scope checking
  def skip_policy_scope_check?
    skip_policy_scope? || !action_name.in?(['index'])
  end
  
  # Check if we're using Devise controllers
  def devise_controller?
    false # Override if using Devise
  end
end
