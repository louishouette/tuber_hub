module Hub
  module Admin
    class FarmUsersController < BaseController
      before_action :set_farm
      before_action :set_farm_user, only: [:destroy]
      
      # GET /hub/admin/farms/:farm_id/users/search
      def search
        authorize @farm, :edit?
        
        @query = params[:query].to_s.strip
        is_recent_request = params[:recent].present?
        
        # Find users not already in this farm
        @users = if is_recent_request || @query.blank?
          # If recent parameter is present or no query, return 5 most recent users not in the farm
          Hub::Admin::User.where.not(id: @farm.user_ids)
                        .order(created_at: :desc)
                        .limit(5)
        else
          # If query is present, search by first name, last name, or email
          Hub::Admin::User.where.not(id: @farm.user_ids)
                        .where('LOWER(first_name) LIKE ? OR LOWER(last_name) LIKE ? OR LOWER(email_address) LIKE ?', 
                                "%#{@query.downcase}%", "%#{@query.downcase}%", "%#{@query.downcase}%")
                        .limit(10)
        end
        
        render json: @users.map { |u| { id: u.id, text: "#{u.full_name} (#{u.email_address})" } }, status: :ok
      end
      
      # POST /hub/admin/farms/:farm_id/users
      def create
        authorize @farm, :edit?
        
        @user = Hub::Admin::User.find_by(email_address: params.expect(:user, :email_address))
        
        if @user.nil?
          redirect_to hub_admin_farm_path(@farm), alert: "User with that email address not found"
          return
        end
        
        # Check if user is already a member of the farm
        if @farm.users.include?(@user)
          redirect_to hub_admin_farm_path(@farm), notice: "User is already a member of this farm"
          return
        end
        
        # Add user to farm
        @farm_user = @farm.farm_users.build(user: @user)
        
        if @farm_user.save
          redirect_to hub_admin_farm_path(@farm), notice: "User was successfully added to the farm"
        else
          redirect_to hub_admin_farm_path(@farm), alert: "Failed to add user to the farm"
        end
      end
      
      # POST /hub/admin/farms/:farm_id/users/add_selected
      def add_selected
        authorize @farm, :edit?
        
        # Handle case where user_ids is nil or empty string
        if params[:user_ids].blank?
          redirect_to hub_admin_farm_path(@farm), alert: "No users selected"
          return
        end
        
        user_ids = params[:user_ids].to_s.split(',').map(&:to_i).reject(&:zero?)
        
        if user_ids.empty?
          redirect_to hub_admin_farm_path(@farm), alert: "No valid users selected"
          return
        end
        
        added_count = 0
        
        user_ids.each do |user_id|
          user = Hub::Admin::User.find_by(id: user_id)
          next if user.nil?
          next if @farm.users.include?(user)
          
          farm_user = @farm.farm_users.build(user: user)
          added_count += 1 if farm_user.save
        end
        
        if added_count > 0
          redirect_to hub_admin_farm_path(@farm), notice: "Added #{added_count} #{'user'.pluralize(added_count)} to the farm"
        else
          redirect_to hub_admin_farm_path(@farm), alert: "No users were added to the farm"
        end
      end
      
      # DELETE /hub/admin/farms/:farm_id/users/:id
      def destroy
        # Don't allow removing the last user from a farm
        if @farm.users.count <= 1
          redirect_to hub_admin_farm_path(@farm), alert: "Cannot remove the last user from a farm"
          return
        end
        
        @farm_user.destroy
        
        redirect_to hub_admin_farm_path(@farm), notice: "User was removed from the farm"
      end
      
      private
      
      def set_farm
        @farm = Hub::Admin::Farm.find(params[:farm_id])
        authorize @farm, :show?
      end
      
      def set_farm_user
        @farm_user = @farm.farm_users.find(params[:id])
        # First verify the user can edit this farm
        authorize @farm, :edit?
        # Then verify they can operate on this specific farm_user
        authorize @farm_user
      end
    end
  end
end
