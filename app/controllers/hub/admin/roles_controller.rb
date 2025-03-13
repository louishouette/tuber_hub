module Hub
  module Admin
    class RolesController < BaseController
      before_action :set_role, only: [:show, :edit, :update, :destroy, :assign_permissions]
      
      def index
        @roles = Hub::Admin::Role.all.order(:name)
      end
      
      def show
      end

      def new
        @role = Hub::Admin::Role.new
      end

      def create
        @role = Hub::Admin::Role.new(role_params)
        
        if @role.save
          redirect_to hub_admin_roles_path, notice: 'Role was successfully created.'
        else
          render :new, status: :unprocessable_entity
        end
      end

      def edit
      end

      def update
        if @role.update(role_params)
          redirect_to hub_admin_roles_path, notice: 'Role was successfully updated.'
        else
          render :edit, status: :unprocessable_entity
        end
      end

      def destroy
        if @role.destroy
          redirect_to hub_admin_roles_path, notice: 'Role was successfully deleted.'
        else
          redirect_to hub_admin_roles_path, alert: 'Could not delete role because it is still in use.'
        end
      end
      
      # Special action to manage permissions for a role
      def assign_permissions
        permission_ids = params[:permission_ids] || []
        
        # Handle the permission assignments
        if params[:commit].present?
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
                expires_at: params[:expires_at].presence
              )
            end
          end
          
          redirect_to hub_admin_role_path(@role), notice: 'Permissions updated successfully'
        else
          # Just display the form
          @permissions = Hub::Admin::Permission.all.order(:namespace, :controller, :action)
          @assigned_permission_ids = @role.permissions.pluck(:id)
          render :assign_permissions
        end
      end
      
      private
      
      def set_role
        @role = Hub::Admin::Role.find(params[:id])
      end
      
      def role_params
        params.expect(:role).permit(:name, :description)
      end
    end
  end
end
