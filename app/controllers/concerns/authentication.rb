module Authentication
  extend ActiveSupport::Concern

  included do
    before_action :require_authentication
    helper_method :authenticated?
  end

  class_methods do
    def allow_unauthenticated_access(**options)
      skip_before_action :require_authentication, **options
    end
    
    # Log an authorization failure for monitoring and analytics
    # @param user [User] the user who experienced the failure
    # @param policy_name [String] the name of the policy that caused the failure
    # @param query [String] the query (method) in the policy that failed
    # @param controller_action [String] the controller and action where the failure occurred
    # @param farm [Farm, nil] the farm context of the failure, if applicable
    def log_authorization_failure(user:, policy_name:, query:, controller_action:, farm: nil)
      # Create an authorization audit entry if the model exists
      if defined?(Hub::Admin::AuthorizationAudit)
        Hub::Admin::AuthorizationAudit.create!(
          user_id: user&.id,
          farm_id: farm&.id,
          policy_name: policy_name,
          query: query,
          controller_action: controller_action,
          ip_address: Current.session&.ip_address,
          user_agent: Current.session&.user_agent
        )
      end
      
      # You could also send this to an external monitoring service if needed
      # For example: Monitoring.report_authorization_failure(...) if defined?(Monitoring)
    end
  end

  private
    def authenticated?
      resume_session
    end

    def require_authentication
      resume_session || request_authentication
    end

    def resume_session
      Current.session ||= find_session_by_cookie
    end

    def find_session_by_cookie
      Session.find_by(id: cookies.signed[:session_id]) if cookies.signed[:session_id]
    end

    def request_authentication
      session[:return_to_after_authenticating] = request.url
      redirect_to login_url
    end

    def after_authentication_url
      session.delete(:return_to_after_authenticating) || root_url
    end

    def start_new_session_for(user)
      # Update sign in related attributes
      user.update(
        last_sign_in_at: Time.zone.now,
        sign_in_count: (user.sign_in_count || 0) + 1,
        current_sign_in_ip: request.remote_ip
      )
      
      user.sessions.create!(user_agent: request.user_agent, ip_address: request.remote_ip).tap do |session|
        Current.session = session
        cookies.signed.permanent[:session_id] = { value: session.id, httponly: true, same_site: :lax }
      end
    end

    def terminate_session
      Current.session.destroy
      cookies.delete(:session_id)
    end
end
