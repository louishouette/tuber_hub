module Hub
  module Admin
    class UsersController < BaseController
      before_action :set_user, only: [:show, :edit, :update, :destroy, :assign_roles]
      
      def index
        @users = Hub::Admin::User.all.order(:email_address)
        @roles = Hub::Admin::Role.all.order(:name)
      end

      def show
      end

      def new
        @user = Hub::Admin::User.new
      end

      def create
        @user = Hub::Admin::User.new(user_params)
        
        if @user.save
          redirect_to hub_admin_users_path, notice: 'User was successfully created.'
        else
          render :new, status: :unprocessable_entity
        end
      end

      def edit
      end

      def update
        if params[:user][:password].blank?
          params[:user].delete(:password)
          params[:user].delete(:password_confirmation)
        end
        
        if @user.update(user_params)
          redirect_to hub_admin_users_path, notice: 'User was successfully updated.'
        else
          render :edit, status: :unprocessable_entity
        end
      end

      def destroy
        if @user.destroy
          redirect_to hub_admin_users_path, notice: 'User was successfully deleted.'
        else
          redirect_to hub_admin_users_path, alert: 'Could not delete user because they have active sessions or assignments.'
        end
      end
      
      # Special action to manage roles for a user
      def assign_roles
        role_ids = params[:role_ids] || []
        
        # Handle the role assignments
        if params[:commit].present?
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
                expires_at: params[:expires_at].presence
              )
            end
          end
          
          redirect_to hub_admin_user_path(@user), notice: 'Roles updated successfully'
        else
          # Just display the form
          @roles = Hub::Admin::Role.all.order(:name)
          @assigned_role_ids = @user.roles.pluck(:id)
          render :assign_roles
        end
      end
      
      private
      
      def set_user
        @user = Hub::Admin::User.find(params[:id])
      end
      
      def user_params
        params.expect(:user).permit(
          :email_address, 
          :first_name, 
          :last_name, 
          :password, 
          :password_confirmation
        )
      end
    end
  end
end
