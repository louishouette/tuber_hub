module Hub
  module Admin
    class PermissionsController < BaseController
      def index
        @permissions = policy_scope(Permission)
          .includes(:roles)
          .order(:namespace, :controller, :action)
          
        # Group permissions by namespace and controller for easier navigation
        @permissions_by_namespace = @permissions.group_by(&:namespace).transform_values do |perms|
          perms.group_by(&:controller)
        end
      end
      
      def show
        @permission = Permission.find(params[:id])
        authorize @permission
        
        @assigned_roles = @permission.roles.order(:name)
      end
    end
  end
end
