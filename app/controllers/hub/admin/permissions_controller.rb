module Hub
  module Admin
    class PermissionsController < BaseController
      before_action :set_permission, only: [:show, :edit, :update, :destroy]
      before_action :load_available_namespaces_and_controllers, only: [:new, :edit, :create, :update]
      
      def index
        @permissions = Permission.all.order(:namespace, :controller, :action)
      end
      
      def show
      end

      def new
        @permission = Permission.new
      end

      def create
        @permission = Permission.new(permission_params)
        
        if @permission.save
          redirect_to hub_admin_permissions_path, notice: 'Permission was successfully created.'
        else
          render :new, status: :unprocessable_entity
        end
      end

      def edit
        # Handle reactivation from index page
        if params[:reactivate].present? && @permission.legacy?
          @permission.mark_as_active!
          redirect_to hub_admin_permissions_path, notice: "Permission '#{@permission.full_identifier}' has been reactivated."
        end
      end

      def update
        if @permission.update(permission_params)
          redirect_to hub_admin_permissions_path, notice: 'Permission was successfully updated.'
        else
          render :edit, status: :unprocessable_entity
        end
      end

      def destroy
        if @permission.destroy
          redirect_to hub_admin_permissions_path, notice: 'Permission was successfully deleted.'
        else
          redirect_to hub_admin_permissions_path, alert: 'Could not delete permission because it is still in use.'
        end
      end

      def generate_permissions
        standard_actions = %w[index show new create edit update destroy]
        created_count = 0
        reactivated_count = 0

        # Dynamically get all Rails controllers in the application
        Rails.application.routes.routes.map do |route|
          next if route.defaults[:controller].blank?
          controller = route.defaults[:controller]
          action = route.defaults[:action]
          next if action.blank?

          # Extract namespace if present
          parts = controller.split('/')
          namespace = parts.size > 1 ? parts[0..-2].join('/') : ''
          controller_name = parts.last

          # Skip routes for Rails internal controllers
          next if namespace.start_with?('rails/')
          
          # Find or create permission
          permission = Permission.find_or_initialize_by(
            namespace: namespace,
            controller: controller_name,
            action: action
          )

          if permission.new_record?
            # New permission
            permission.description = "#{action.capitalize} #{controller_name.singularize} in #{namespace.presence || 'main app'}"
            permission.status = Permission::STATUSES[:active]
            created_count += 1 if permission.save
          elsif permission.legacy?
            # Reactivate legacy permission since it exists in routes again
            if permission.mark_as_active!
              reactivated_count += 1
            end
          end
        end

        # Mark permissions that are no longer in routes as legacy
        legacy_count = Permission.mark_legacy_permissions!

        message = []
        message << "Successfully generated #{created_count} new permissions." if created_count > 0
        message << "Reactivated #{reactivated_count} legacy permissions." if reactivated_count > 0
        message << "Marked #{legacy_count} permissions as legacy." if legacy_count > 0
        
        redirect_to hub_admin_permissions_path, notice: message.join(' ')
      end

      # AJAX endpoint to get controllers for a namespace
      def controllers_for_namespace
        namespace = params[:namespace].to_s
        controllers = []

        # Find all controllers in this namespace from routes
        Rails.application.routes.routes.map do |route|
          next if route.defaults[:controller].blank?
          controller = route.defaults[:controller]
          
          # Extract namespace and controller name
          parts = controller.split('/')
          route_namespace = parts.size > 1 ? parts[0..-2].join('/') : ''
          controller_name = parts.last

          # Add controller if it matches the requested namespace
          if route_namespace == namespace && !controllers.include?(controller_name)
            controllers << controller_name
          end
        end

        render json: { controllers: controllers.sort }
      end
      
      private
      
      def set_permission
        @permission = Permission.find(params[:id])
      end
      
      def permission_params
        params.expect(:permission).permit(:namespace, :controller, :action, :description)
      end

      def load_available_namespaces_and_controllers
        @available_namespaces = []
        @available_controllers = {}

        # Dynamically gather all controllers and their namespaces from routes
        Rails.application.routes.routes.map do |route|
          next if route.defaults[:controller].blank?
          controller = route.defaults[:controller]
          
          # Extract namespace if present
          parts = controller.split('/')
          namespace = parts.size > 1 ? parts[0..-2].join('/') : ''
          controller_name = parts.last

          # Skip routes for Rails internal controllers
          next if namespace.start_with?('rails/')
          
          @available_namespaces << namespace unless @available_namespaces.include?(namespace)
          
          @available_controllers[namespace] ||= []
          @available_controllers[namespace] << controller_name unless @available_controllers[namespace].include?(controller_name)
        end
        
        # Sort for better display
        @available_namespaces.sort!
        @available_controllers.each do |namespace, controllers|
          @available_controllers[namespace] = controllers.sort
        end

        # Standard actions for all controllers
        @standard_actions = %w[index show new create edit update destroy]
      end
    end
  end
end
