module Hub
  module Admin
    class BaseController < Hub::BaseController
      before_action :require_admin!
      skip_before_action :authorize_for_namespace!, raise: false
      
      private
      
      def require_admin!
        unless Current.user&.admin?
          redirect_back fallback_location: hub_path, alert: "You must be an administrator to access this area"
        end
      end
    end
  end
end
