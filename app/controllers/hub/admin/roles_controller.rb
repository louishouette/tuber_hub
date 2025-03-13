module Hub
  module Admin
    class RolesController < BaseController
      before_action :set_role, only: [:show, :edit, :update, :destroy, :users, :assign_permissions]
      
      def index
        @roles = policy_scope(Role)
          .order(:name)
          .includes(:permission_assignments)
      end
      
      def show
        authorize @role
      end

      def new
        @role = Hub::Admin::Role.new
        authorize @role
      end

      def create
        @role = Hub::Admin::Role.new(role_params)
        authorize @role
        
        if @role.save
          redirect_to hub_admin_roles_path, notice: 'Role was successfully created.'
        else
          render :new, status: :unprocessable_entity
        end
      end

      def edit
        authorize @role
      end

      def update
        authorize @role
        if @role.update(role_params)
          redirect_to hub_admin_roles_path, notice: 'Role was successfully updated.'
        else
          render :edit, status: :unprocessable_entity
        end
      end

      def destroy
        authorize @role
        if @role.destroy
          redirect_to hub_admin_roles_path, notice: 'Role was successfully deleted.'
        else
          redirect_to hub_admin_roles_path, alert: 'Could not delete role because it is still in use.'
        end
      end
      
      # Show users with this role
      def users
        authorize @role, :users?
        @users = @role.users
          .order(:last_name, :first_name)
      end
      
      # Special action to manage permissions for a role
      def assign_permissions
        authorize @role, :assign_permissions?
        
        if request.post?
          role_params = params.expect(role: [:permission_ids, :expires_at])
          permission_ids = role_params[:role][:permission_ids] || []
          expires_at = role_params[:role][:expires_at].presence
          
          # Remove permissions that were unchecked
          @role.permission_assignments.where.not(permission_id: permission_ids).each do |assignment|
            assignment.revoke!(Current.user)
          end
          
          # Add new permissions
          permission_ids.each do |permission_id|
            unless @role.permission_assignments.exists?(permission_id: permission_id)
              @role.permission_assignments.create!(
                permission_id: permission_id,
                granted_by: Current.user,
                expires_at: expires_at
              )
            end
          end
          
          redirect_to hub_admin_role_path(@role), notice: 'Permissions updated successfully'
        else
          # Just display the form
          @permissions = Hub::Admin::Permission.where(status: 'active')
            .order(:namespace, :controller, :action)
            
          # Group permissions by namespace and controller for easier navigation
          @permissions_by_namespace = @permissions.group_by(&:namespace).transform_values do |perms|
            perms.group_by(&:controller)
          end
            
          @assigned_permission_ids = @role.permissions.pluck(:id)
        end
      end
      
      
      private
      
      def set_role
        @role = Hub::Admin::Role.find(params[:id])
      end
      
      # For now, revert to params.require until we can debug the params.expect issue
      def role_params
        params.require(:hub_admin_role).permit(:name, :description)
      end
    end
  end
end
