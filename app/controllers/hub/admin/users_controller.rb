module Hub
  module Admin
    class UsersController < BaseController
      before_action :set_user, only: [:show, :edit, :update, :destroy, :assign_roles, :toggle_active, :set_default_farm, :update_preference]
      
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
        @farm_preferences = @user.farms.order(:name) if @user == Current.user
        @current_preferences = {
          items_per_page: @user.items_per_page,
          notifications_enabled: @user.notifications_enabled?
        } if @user == Current.user
      end

      def new
        @user = User.new
        authorize @user
      end

      def create
        @user = User.new(user_params)
        authorize @user
        
        # Attempt to save inside a transaction to ensure all associations are created
        ActiveRecord::Base.transaction do
          if @user.save
            # Associate with farm
            if params[:user][:farm_id].present?
              farm = Farm.find(params[:user][:farm_id])
              farm_user = Hub::Admin::FarmUser.new(farm: farm, user: @user)
              farm_user.save!
            end
            
            # Assign role
            if params[:user][:role_id].present?
              role = Role.find(params[:user][:role_id])
              assignment = Hub::Admin::RoleAssignment.new(
                user: @user,
                role: role,
                granted_by: Current.user,
                global: true
              )
              assignment.save!
            end
            
            redirect_to hub_admin_users_path, notice: "User #{@user.full_name} was successfully created."
            return
          end
        end
        
        # If we got here, there was an error
        @farms = Hub::Admin::Farm.all.order(:name)
        @roles = Hub::Admin::Role.all.order(:name)
        render :new, status: :unprocessable_entity
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
          redirect_to hub_admin_users_path, notice: "User #{@user.full_name} was successfully updated."
        else
          render :edit, status: :unprocessable_entity
        end
      end

      def destroy
        authorize @user
        
        if @user.destroy
          redirect_to hub_admin_users_path, notice: "User #{@user.full_name} was successfully deleted."
        else
          redirect_to hub_admin_users_path, alert: "Could not delete user #{@user.full_name} because they have active sessions or assignments."
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
          redirect_to hub_admin_user_path(@user), alert: "Could not change status for user #{@user.full_name}."
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
          

        end
        
        redirect_to hub_admin_user_path(@user), notice: 'Roles updated successfully'
      end
      
      # Set default farm preference
      def set_default_farm
        authorize @user, :update?
        
        farm_id = params[:farm_id]
        
        if farm_id.blank?
          # Clear default farm if no farm_id provided
          @user.clear_default_farm
          redirect_back(fallback_location: hub_admin_user_path(@user), notice: "Default farm preference cleared")
          return
        end
        
        farm = Hub::Admin::Farm.find_by(id: farm_id)
        
        if farm && @user.farms.include?(farm) && @user.set_default_farm(farm)
          redirect_back(fallback_location: hub_admin_user_path(@user), notice: "Default farm set to #{farm.name}")
        else
          redirect_back(fallback_location: hub_admin_user_path(@user), alert: "Could not set default farm")
        end
      end
      
      # Update user preference
      def update_preference
        authorize @user, :update?
        
        key = params[:key]
        value = params[:value]
        
        if @user.set_preference(key, value)
          respond_to do |format|
            format.html { redirect_back(fallback_location: hub_admin_user_path(@user), notice: "Preference updated successfully") }
            format.json { render json: { success: true } }
          end
        else
          respond_to do |format|
            format.html { redirect_back(fallback_location: hub_admin_user_path(@user), alert: "Could not update preference") }
            format.json { render json: { success: false }, status: :unprocessable_entity }
          end
        end
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
