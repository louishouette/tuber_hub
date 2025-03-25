module Hub
  module Admin
    class FarmsController < BaseController
      skip_before_action :authorize_admin_access, only: [:set_current_farm]
      before_action :set_farm, only: [:show, :edit, :update, :destroy]
      
      def index
        @farms = policy_scope(Farm)
      end

      def show
      end

      def new
        @farm = Farm.new
        authorize @farm
      end

      def create
        @farm = Farm.new(farm_params)
        authorize @farm

        if @farm.save
          # Associate the farm with the current user
          Current.user.add_to_farm(@farm)
          
          # Also set as current farm in the session
          session[:current_farm_id] = @farm.id
          
          # Redirect with success message
          redirect_to hub_admin_farm_path(@farm), notice: 'Farm was successfully created.'
        else
          render :new, status: :unprocessable_entity
        end
      end

      def edit
      end

      def update
        if @farm.update(farm_params)
          redirect_to hub_admin_farm_path(@farm), notice: 'Farm was successfully updated.'
        else
          render :edit, status: :unprocessable_entity
        end
      end

      def destroy
        @farm.destroy
        redirect_to hub_admin_farms_path, notice: 'Farm was successfully deleted.'
      end
      
      # Sets the current farm for the user session
      def set_current_farm
        @farm = Farm.find(params[:farm_id])
        authorize @farm, :set_current_farm?
        
        # Store the current farm_id in session
        session[:current_farm_id] = @farm.id
        
        # Also set as default farm in user preferences if requested
        if params[:set_as_default].present? && params[:set_as_default] == 'true'
          Current.user.set_default_farm(@farm)
          notice_message = "Switched to #{@farm.name} and set as your default farm"
        else
          notice_message = "Switched to #{@farm.name}"
        end
        
        # Redirect back to the previous page or default route
        redirect_back(fallback_location: hub_path, notice: notice_message)
      end

      private

      def set_farm
        @farm = Farm.find(params[:id])
        authorize @farm
      end

      def farm_params
        params.expect(:farm).permit(:name, :handle, :address, :description, :logo, :active)
      end
    end
  end
end
