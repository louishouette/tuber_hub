module Hub
  class BaseController < HubController
    # Authorization for namespace-specific resources
    before_action :authorize_for_namespace!
    
    private
    
    # Check if user has permission to access resources in the current namespace/controller
    def authorize_for_namespace!
      namespace = controller_path.split('/')[0..1].join('/')
      controller = controller_name
      
      unless Current.user&.admin? || Current.user&.can?(action_name, namespace, controller)
        redirect_back fallback_location: root_path, alert: "You don't have permission to access this resource"
      end
    end
  end
end
