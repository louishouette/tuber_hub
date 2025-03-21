module Hub
  module Admin
    class FarmUsersController < BaseController
      before_action :set_farm
      before_action :set_farm_user, only: [:destroy]
      skip_after_action :verify_policy_scoped
      
      # GET /hub/admin/farms/:farm_id/users/search
      def search
        Rails.logger.debug "DEBUG: Entering search action with farm_id=#{params[:farm_id]}"
        Rails.logger.debug "DEBUG: Current request path=#{request.path}"
        Rails.logger.debug "DEBUG: Query params=#{params.inspect}"
        
        # Check that farm was properly loaded
        unless @farm && @farm.id.present?
          Rails.logger.error "ERROR: Farm not properly loaded in search action"
          render json: { error: 'Farm not found' }, status: :not_found
          return
        end
        
        authorize @farm, :edit?
        
        @query = params[:query].to_s.strip
        is_recent_request = params[:recent].present?
        
        Rails.logger.debug "DEBUG: Processing search with query=#{@query}, recent=#{is_recent_request}"
        
        # Find users not already in this farm
        @users = if is_recent_request || @query.blank?
          # If recent parameter is present or no query, return 5 most recent users not in the farm
          users = Hub::Admin::User.where.not(id: @farm.user_ids)
                        .order(created_at: :desc)
                        .limit(5)
          Rails.logger.debug "DEBUG: Found #{users.size} recent users not in farm"
          users
        else
          # If query is present, search by first name, last name, or email
          users = Hub::Admin::User.where.not(id: @farm.user_ids)
                        .where('LOWER(first_name) LIKE ? OR LOWER(last_name) LIKE ? OR LOWER(email_address) LIKE ?', 
                                "%#{@query.downcase}%", "%#{@query.downcase}%", "%#{@query.downcase}%")
                        .limit(10)
          Rails.logger.debug "DEBUG: Found #{users.size} users matching '#{@query}' not in farm"
          users
        end
        
        result = @users.map { |u| { id: u.id, text: "#{u.full_name} (#{u.email_address})" } }
        Rails.logger.debug "DEBUG: Returning #{result.size} users as JSON"
        
        render json: result, status: :ok
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
        Rails.logger.debug "DEBUG: Setting farm with farm_id=#{params[:farm_id]}"
        begin
          @farm = Hub::Admin::Farm.find(params[:farm_id])
          Rails.logger.debug "DEBUG: Farm found with ID #{@farm.id}, name: #{@farm.name}"
          authorize @farm, :show?
        rescue ActiveRecord::RecordNotFound => e
          Rails.logger.error "ERROR: Farm not found with ID #{params[:farm_id]}: #{e.message}"
          render json: { error: 'Farm not found' }, status: :not_found and return if request.format.json?
          redirect_to hub_admin_farms_path, alert: "Farm not found" and return
        rescue Pundit::NotAuthorizedError => e
          Rails.logger.error "ERROR: User not authorized to access farm: #{e.message}"
          render json: { error: 'Not authorized' }, status: :forbidden and return if request.format.json?
          redirect_to hub_admin_farms_path, alert: "You don't have permission to access that farm" and return
        end
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
