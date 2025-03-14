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
          redirect_to hub_admin_users_path, notice: 'User was successfully updated.'
        else
          render :edit, status: :unprocessable_entity
        end
      end

      def destroy
        authorize @user
        
        if @user.destroy
          redirect_to hub_admin_users_path, notice: 'User was successfully deleted.'
        else
          redirect_to hub_admin_users_path, alert: 'Could not delete user because they have active sessions or assignments.'
        end
      end
      
      # Toggle user active status
      def toggle_active
        authorize @user, :toggle_active?
        
        new_status = !@user.active?
        if @user.update(active: new_status)
          status_message = new_status ? 'activated' : 'deactivated'
          redirect_to hub_admin_user_path(@user), notice: "User #{@user.full_name} has been #{status_message}."
        else
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
