# frozen_string_literal: true

module Hub
  module Admin
    # Controller for managing user preferences
    class UserPreferencesController < BaseController
      before_action :set_user_preference, only: [:show, :edit, :update, :destroy]
      
      def index
        @user_preferences = policy_scope(UserPreference)
          .where(user: Current.user)
          .order(:key)
          .page(params[:page])
          .per(Current.user.items_per_page)
      end

      def show
        authorize @user_preference
      end

      def new
        @user_preference = UserPreference.new(user: Current.user)
        authorize @user_preference
      end

      def edit
        authorize @user_preference
      end

      def create
        @user_preference = UserPreference.new(user_preference_params)
        @user_preference.user = Current.user
        authorize @user_preference
        
        if @user_preference.save
          redirect_to hub_admin_user_preferences_path, notice: "Preference '#{@user_preference.key}' was successfully created."
        else
          render :new, status: :unprocessable_entity
        end
      end

      def update
        authorize @user_preference
        
        if @user_preference.update_value(user_preference_params[:value])
          redirect_to hub_admin_user_preferences_path, notice: "Preference '#{@user_preference.key}' was successfully updated."
        else
          render :edit, status: :unprocessable_entity
        end
      end

      def destroy
        authorize @user_preference
        key = @user_preference.key
        
        if @user_preference.destroy
          redirect_to hub_admin_user_preferences_path, notice: "Preference '#{key}' was successfully deleted."
        else
          redirect_to hub_admin_user_preferences_path, alert: "Could not delete preference '#{key}'."
        end
      end
      
      # Settings page for managing all preferences in one place
      def settings
        authorize UserPreference, :index?
        @farm_preferences = Current.user.farms.order(:name)
        @current_preferences = {
          items_per_page: Current.user.items_per_page,
          notifications_enabled: Current.user.notifications_enabled?
        }
      end
      
      # Set default farm preference
      def set_default_farm
        authorize UserPreference, :update?
        
        farm_id = params[:farm_id]
        
        if farm_id.blank?
          # Clear default farm if no farm_id provided
          Current.user.clear_default_farm
          redirect_back(fallback_location: hub_admin_dashboard_path, notice: "Default farm preference cleared")
          return
        end
        
        farm = Hub::Admin::Farm.find_by(id: farm_id)
        
        if farm && Current.user.farms.include?(farm) && Current.user.set_default_farm(farm)
          redirect_back(fallback_location: hub_admin_dashboard_path, notice: "Default farm set to #{farm.name}")
        else
          redirect_back(fallback_location: hub_admin_dashboard_path, alert: "Could not set default farm")
        end
      end
      
      # Bulk update of user preferences
      def update_preference
        authorize UserPreference, :update?
        
        key = params[:key]
        value = params[:value]
        
        if Current.user.set_preference(key, value)
          respond_to do |format|
            format.html { redirect_back(fallback_location: settings_hub_admin_user_preferences_path, notice: "Preference updated successfully") }
            format.json { render json: { success: true } }
          end
        else
          respond_to do |format|
            format.html { redirect_back(fallback_location: settings_hub_admin_user_preferences_path, alert: "Could not update preference") }
            format.json { render json: { success: false }, status: :unprocessable_entity }
          end
        end
      end
      
      private
      
      def set_user_preference
        @user_preference = UserPreference.find(params[:id])
      end
      
      def user_preference_params
        params.expect(:user_preference).permit(:key, :value)
      end
    end
  end
end
