module Hub
  module Admin
    class PermissionAssignmentsController < BaseController
      before_action :set_permission_assignment, only: [:destroy]
      
      def index
        @permission_assignments = Hub::Admin::PermissionAssignment.includes(:permission, :role, :granted_by)
                                               .order('hub_admin_roles.name', 'hub_admin_permissions.namespace', 
                                                      'hub_admin_permissions.controller', 'hub_admin_permissions.action')
      end

      def new
        @permission_assignment = Hub::Admin::PermissionAssignment.new
        @permissions = Hub::Admin::Permission.all.order(:namespace, :controller, :action)
        @roles = Hub::Admin::Role.all.order(:name)
      end

      def create
        @permission_assignment = Hub::Admin::PermissionAssignment.new(permission_assignment_params)
        @permission_assignment.granted_by = Current.user
        
        if @permission_assignment.save
          redirect_to hub_admin_permission_assignments_path, notice: 'Permission assignment was successfully created.'
        else
          @permissions = Hub::Admin::Permission.all.order(:namespace, :controller, :action)
          @roles = Hub::Admin::Role.all.order(:name)
          render :new, status: :unprocessable_entity
        end
      end

      def destroy
        @permission_assignment.revoke!(Current.user)
        redirect_to hub_admin_permission_assignments_path, notice: 'Permission assignment was successfully revoked.'
      end
      
      private
      
      def set_permission_assignment
        @permission_assignment = Hub::Admin::PermissionAssignment.find(params[:id])
      end
      
      def permission_assignment_params
        params.expect(:permission_assignment).permit(:role_id, :permission_id, :expires_at)
      end
    end
  end
end
