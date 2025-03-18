module Hub
  module Admin
    class UsersController < BaseController
      before_action :set_user, only: [:show, :edit, :update, :destroy, :assign_roles, :toggle_active]
      
      def index
        @users = policy_scope(User)
          .order(:last_name, :first_name, :email_address)
          .includes(:roles)
        @roles = Hub::Admin::Role.all.order(:name)
      end

      # Filter users by role
      def by_role
        authorize User, :by_role?
        @role = Role.find(params[:role_id])
        @users = @role.users.order(:last_name, :first_name, :email_address)
        render :index
      end

      def show
        authorize @user
      end

      def new
        @user = User.new
        authorize @user
      end

      def create
        @user = User.new(user_params)
        authorize @user
        
        if @user.save
          # Send notification to the user who performed the action
          Hub::NotificationService.notify(
            user: Current.user,
            message: "User #{@user.full_name} was successfully created",
            notification_type: 'success',
            metadata: { user_id: @user.id }
          )
          
          redirect_to hub_admin_users_path, notice: 'User was successfully created.'
        else
          render :new, status: :unprocessable_entity
        end
      end

      def edit
        authorize @user
        # Add a hidden debug field to help troubleshoot
        @debug_info = {
          model_name: @user.model_name.param_key,
          class_name: @user.class.name
        }
      end

      def update
        authorize @user
        
        # Handle password update
        user_update_params = user_params
        if user_update_params[:password].blank?
          user_update_params = user_update_params.except(:password, :password_confirmation)
        end
        
        if @user.update(user_update_params)
          # Send notification to the user who performed the action
          Hub::NotificationService.notify(
            user: Current.user,
            message: "User #{@user.full_name} was successfully updated",
            notification_type: 'success',
            metadata: { user_id: @user.id }
          )
          
          redirect_to hub_admin_users_path, notice: 'User was successfully updated.'
        else
          render :edit, status: :unprocessable_entity
        end
      end

      def destroy
        authorize @user
        
        if @user.destroy
          # Send notification to the user who performed the action
          Hub::NotificationService.notify(
            user: Current.user,
            message: "User #{@user.full_name} was successfully deleted",
            notification_type: 'success',
            metadata: { user_id: @user.id }
          )
          
          redirect_to hub_admin_users_path, notice: 'User was successfully deleted.'
        else
          # Send error notification
          Hub::NotificationService.notify(
            user: Current.user,
            message: "Failed to delete user #{@user.full_name}",
            notification_type: 'error',
            metadata: { user_id: @user.id, error: "User has active sessions or assignments" }
          )
          
          redirect_to hub_admin_users_path, alert: 'Could not delete user because they have active sessions or assignments.'
        end
      end
      
      # Toggle user active status
      def toggle_active
        authorize @user, :toggle_active?
        
        new_status = !@user.active?
        if @user.update(active: new_status)
          status_message = new_status ? 'activated' : 'deactivated'
          
          # Send notification to the user who performed the action
          Hub::NotificationService.notify(
            user: Current.user,
            message: "User #{@user.full_name} has been #{status_message}",
            notification_type: 'success',
            metadata: { user_id: @user.id, status: new_status ? 'active' : 'inactive' }
          )
          
          redirect_to hub_admin_user_path(@user), notice: "User #{@user.full_name} has been #{status_message}."
        else
          # Send error notification
          Hub::NotificationService.notify(
            user: Current.user,
            message: "Failed to change status for user #{@user.full_name}",
            notification_type: 'error',
            metadata: { user_id: @user.id }
          )
          
          redirect_to hub_admin_user_path(@user), alert: 'Could not change user status.'
        end
      end
      
      # Special action to manage roles for a user
      def assign_roles
        authorize @user, :assign_roles?
        
        # Redirect to show page if accessed via GET (since assignment is now embedded)
        redirect_to hub_admin_user_path(@user) and return unless request.post?
        
        user_params = params.require(:user).permit(:expires_at, role_ids: [])
        role_ids = user_params[:role_ids] || []
        expires_at = user_params[:expires_at].presence
        
        # Track role changes for notification
        previous_role_ids = @user.role_ids.to_set
        new_role_ids = role_ids.map(&:to_i).to_set
        added_role_ids = new_role_ids - previous_role_ids
        removed_role_ids = previous_role_ids - new_role_ids
        
        # Remove roles that were unchecked
        @user.role_assignments.where.not(role_id: role_ids).each do |assignment|
          assignment.revoke!(Current.user)
        end
        
        # Add new roles
        role_ids.each do |role_id|
          unless @user.role_assignments.exists?(role_id: role_id)
            @user.role_assignments.create!(
              role_id: role_id,
              granted_by: Current.user,
              expires_at: expires_at
            )
          end
        end
        
        # Create notification with specific details about role changes
        if added_role_ids.any? || removed_role_ids.any?
          # Get role names for better notification readability
          added_roles = Hub::Admin::Role.where(id: added_role_ids.to_a).pluck(:name).join(', ')
          removed_roles = Hub::Admin::Role.where(id: removed_role_ids.to_a).pluck(:name).join(', ')
          
          changes = []
          changes << "Added roles: #{added_roles}" if added_roles.present?
          changes << "Removed roles: #{removed_roles}" if removed_roles.present?
          
          Hub::NotificationService.notify(
            user: Current.user,
            message: "Updated roles for user #{@user.full_name}",
            notification_type: 'success',
            metadata: {
              user_id: @user.id,
              added_role_ids: added_role_ids.to_a,
              removed_role_ids: removed_role_ids.to_a,
              changes: changes.join('; ')
            }
          )
        end
        
        redirect_to hub_admin_user_path(@user), notice: 'Roles updated successfully'
      end
      
      private
      
      def set_user
        @user = Hub::Admin::User.find(params[:id])
      end
      
      def user_params
        params.require(:user).permit(
          :email_address, 
          :first_name, 
          :last_name, 
          :phone_number,
          :job_title,
          :notes,
          :active,
          :password, 
          :password_confirmation
        )
      end
    end
  end
end
