class ApplicationController < ActionController::Base
  include Authentication
  include Pundit::Authorization
  include PunditHelper
  include CurrentFarm

  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Ensure authorization is applied to all actions except specified ones
  after_action :verify_authorized, except: [:index], unless: :skip_authorization?
  after_action :verify_policy_scoped, only: [:index], unless: :skip_policy_scope_check?

  # Globally rescue from Pundit::NotAuthorizedError
  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  private

  def user_not_authorized
    respond_to do |format|
      format.html do
        flash[:alert] = "You are not authorized to perform this action."
        redirect_to(request.referrer || root_path)
      end
      format.json { render json: { error: 'Not authorized' }, status: :forbidden }
      format.js { head :forbidden }
    end
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
