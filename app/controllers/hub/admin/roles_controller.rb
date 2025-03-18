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
          # Send notification to the user who performed the action
          Hub::NotificationService.notify(
            user: Current.user,
            message: "Role '#{@role.name}' was successfully created",
            notification_type: 'success',
            metadata: { role_id: @role.id }
          )
          
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
          # Send notification to the user who performed the action
          Hub::NotificationService.notify(
            user: Current.user,
            message: "Role '#{@role.name}' was successfully updated",
            notification_type: 'success',
            metadata: { role_id: @role.id }
          )
          
          redirect_to hub_admin_roles_path, notice: 'Role was successfully updated.'
        else
          render :edit, status: :unprocessable_entity
        end
      end

      def destroy
        authorize @role
        if @role.destroy
          # Send notification to the user who performed the action
          Hub::NotificationService.notify(
            user: Current.user,
            message: "Role '#{@role.name}' was successfully deleted",
            notification_type: 'success',
            metadata: { role_id: @role.id }
          )
          
          redirect_to hub_admin_roles_path, notice: 'Role was successfully deleted.'
        else
          # Send error notification
          Hub::NotificationService.notify(
            user: Current.user,
            message: "Failed to delete role '#{@role.name}'",
            notification_type: 'error',
            metadata: { role_id: @role.id, error: "Role is still in use" }
          )
          
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
        
        # Redirect to show page if accessed via GET (since assignment is now embedded)
        redirect_to hub_admin_role_path(@role) and return unless request.post?
        
        role_params = params.require(:role).permit(:expires_at, permission_ids: [])
        permission_ids = role_params[:permission_ids] || []
        expires_at = role_params[:expires_at].presence
        
        # Track permission changes for notification
        previous_permission_ids = @role.permission_ids.to_set
        new_permission_ids = permission_ids.map(&:to_i).to_set
        added_permission_ids = new_permission_ids - previous_permission_ids
        removed_permission_ids = previous_permission_ids - new_permission_ids
        
        # Wrap in a transaction to ensure all or nothing completes
        ActiveRecord::Base.transaction do
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
        end
        
        # Create notification with specific details about permission changes
        if added_permission_ids.any? || removed_permission_ids.any?
          # Get permission details for better notification readability
          added_count = added_permission_ids.size
          removed_count = removed_permission_ids.size
          
          Hub::NotificationService.notify(
            user: Current.user,
            message: "Updated permissions for role '#{@role.name}'",
            notification_type: 'success',
            metadata: {
              role_id: @role.id,
              added_permission_count: added_count,
              removed_permission_count: removed_count,
              changes: "Added #{added_count} permissions; Removed #{removed_count} permissions"
            }
          )
        end
        
        redirect_to hub_admin_role_path(@role), notice: 'Permissions updated successfully'
      end
      
      
      private
      
      def set_role
        @role = Hub::Admin::Role.find(params[:id])
      end
      
      # Strong parameters for role model
      def role_params
        params.require(:hub_admin_role).permit(:name, :description)
      end
    end
  end
end
