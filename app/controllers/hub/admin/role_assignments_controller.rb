module Hub
  module Admin
    class RoleAssignmentsController < BaseController
      before_action :set_role_assignment, only: [:destroy]
      
      def index
        @role_assignments = Hub::Admin::RoleAssignment.includes(:user, :role, :granted_by)
                                       .order('hub_admin_users.email_address', 'hub_admin_roles.name')
      end

      def new
        @role_assignment = Hub::Admin::RoleAssignment.new
        @users = Hub::Admin::User.all.order(:email_address)
        @roles = Hub::Admin::Role.all.order(:name)
      end

      def create
        @role_assignment = Hub::Admin::RoleAssignment.new(role_assignment_params)
        @role_assignment.granted_by = Current.user
        
        if @role_assignment.save
          redirect_to hub_admin_role_assignments_path, notice: 'Role assignment was successfully created.'
        else
          @users = Hub::Admin::User.all.order(:email_address)
          @roles = Hub::Admin::Role.all.order(:name)
          render :new, status: :unprocessable_entity
        end
      end

      def destroy
        @role_assignment.revoke!(Current.user)
        redirect_to hub_admin_role_assignments_path, notice: 'Role assignment was successfully revoked.'
      end
      
      private
      
      def set_role_assignment
        @role_assignment = Hub::Admin::RoleAssignment.find(params[:id])
      end
      
      def role_assignment_params
        params.expect(:role_assignment).permit(:user_id, :role_id, :expires_at)
      end
    end
  end
end
