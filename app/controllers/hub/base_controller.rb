module Hub
  class BaseController < HubController
    # Authorization for namespace-specific resources
    before_action :authorize_namespace_access
    
    private
    
    # Authorize access to namespace resources using standard Pundit pattern
    def authorize_namespace_access
      namespace_params = { 
        namespace: controller_path.split('/')[0..1].join('/'),
        controller: controller_name,
        action: action_name
      }
      
      # Use standard Pundit authorize with inferred action method
      authorize namespace_params, policy_class: NamespacePolicy
    rescue Pundit::NotAuthorizedError
      redirect_back fallback_location: root_path, alert: "You don't have permission to access this resource"
    end
  end
end
