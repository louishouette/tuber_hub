module Hub
  module Admin
    class PermissionsController < BaseController
      def index
        # Filter params
        @filter_namespace = params[:namespace]
        @filter_type = params[:type] || 'crud' # Default to CRUD
        
        # Start with base scope
        permissions_scope = policy_scope(Permission).includes(:roles)
        
        # Apply namespace filter if provided
        permissions_scope = permissions_scope.by_namespace(@filter_namespace) if @filter_namespace.present?
        
        # Filter by type (CRUD vs custom actions vs Pundit-compatible)
        case @filter_type
        when 'crud'
          permissions_scope = permissions_scope.where(action: PermissionService.crud_actions)
        when 'custom'
          permissions_scope = permissions_scope.where.not(action: PermissionService.crud_actions)
        when 'pundit'
          # Fetch all Pundit-compatible actions - both standard CRUD and custom ones
          pundit_actions = PermissionService.pundit_controllable_actions(include_all: true)
          permissions_scope = permissions_scope.where(action: pundit_actions)
        end
        
        # Always filter out system controllers/actions
        system_controllers = %w[application sessions passwords]
        system_actions = %w[authorize_namespace namespace_scope allowed_to? user_is_admin?]
        
        permissions_scope = permissions_scope.where.not(controller: system_controllers)
        permissions_scope = permissions_scope.where.not(action: system_actions)
        
        # Filter out permissions from controllers that don't require authentication
        # This would include PublicController and any controllers that inherit from it
        # like Public::AboutController which has allow_unauthenticated_access
        if @filter_namespace == 'public'
          # If we're specifically viewing public namespace permissions, show all of them
          # but still filter out any other unauthenticated controllers
          unauthenticated_controllers = PermissionService.find_unauthenticated_controllers.reject { |c| c.starts_with?('public/') }
          permissions_scope = permissions_scope.where.not(controller: unauthenticated_controllers) if unauthenticated_controllers.any?
        else
          # For other namespaces, filter out all unauthenticated controllers
          unauthenticated_controllers = PermissionService.find_unauthenticated_controllers
          permissions_scope = permissions_scope.where.not(controller: unauthenticated_controllers) if unauthenticated_controllers.any?
        end
        
        # Get all available namespaces using the model method
        @available_namespaces = Permission.available_namespaces
        
        # Final ordered result
        @permissions = permissions_scope.order(:namespace, :controller, :action)
          
        # Group permissions by namespace and controller for easier navigation
        @permissions_by_namespace = @permissions.group_by(&:namespace).transform_values do |perms|
          perms.group_by(&:controller)
        end
      end
      
      def show
        @permission = Permission.find(params[:id])
        authorize @permission
        
        # Get roles that have this permission
        @assigned_roles = @permission.roles.distinct.order(:name)
        
        # Get users with this permission through their roles
        @assigned_users = User.joins(roles: :permissions)
          .where(hub_admin_permissions: { id: @permission.id })
          .distinct
          .order(:email_address)
      end
      
      # Refresh permissions from controllers
      def refresh
        authorize Permission, :refresh?
        
        # Handle different formats based on the request
        respond_to do |format|
          if PermissionService.refresh_permissions
            # Get the count of active permissions for notification
            permission_count = Hub::Admin::Permission.count
            
            # Send notification
            Hub::NotificationService.notify(
              user: Current.user,
              message: "Permissions refreshed successfully",
              notification_type: 'success',
              metadata: { permission_count: permission_count }
            )
            
            # Update the UI after successful refresh
            format.html { redirect_to hub_admin_permissions_path, notice: 'Permissions have been refreshed from controllers.' }
            format.turbo_stream do
              # Re-fetch the filtered permissions
              @filter_namespace = params[:namespace]
              @filter_controller = params[:controller_name]
              @filter_type = params[:type] || 'crud'
              
              # Get fresh data after the refresh
              @available_namespaces = Permission.available_namespaces
              @available_controllers = Permission.distinct.pluck(:controller).compact.reject { |c| c.include?(':') }.sort
              
              # Rebuild the permissions collection
              permissions_scope = policy_scope(Permission).includes(:roles)
              permissions_scope = permissions_scope.by_namespace(@filter_namespace) if @filter_namespace.present?
              permissions_scope = permissions_scope.by_controller(@filter_controller) if @filter_controller.present?
              
              # Filter by type (CRUD vs custom actions vs Pundit-compatible)
              case @filter_type
              when 'crud'
                permissions_scope = permissions_scope.where(action: PermissionService.crud_actions)
              when 'custom'
                permissions_scope = permissions_scope.where.not(action: PermissionService.crud_actions)
              when 'pundit'
                # Fetch all Pundit-compatible actions - both standard CRUD and custom ones
                pundit_actions = PermissionService.pundit_controllable_actions(include_all: true)
                permissions_scope = permissions_scope.where(action: pundit_actions)
              end
              
              # Always filter out system controllers/actions
              system_controllers = %w[application sessions passwords]
              system_actions = %w[authorize_namespace namespace_scope allowed_to? user_is_admin?]
              permissions_scope = permissions_scope.where.not(controller: system_controllers)
              permissions_scope = permissions_scope.where.not(action: system_actions)
              
              # Filter out controllers that don't require authentication
              if @filter_namespace == 'public'
                # If we're specifically viewing public namespace permissions, show all of them
                # but still filter out any other unauthenticated controllers
                unauthenticated_controllers = PermissionService.find_unauthenticated_controllers.reject { |c| c.starts_with?('public/') }
                permissions_scope = permissions_scope.where.not(controller: unauthenticated_controllers) if unauthenticated_controllers.any?
              else
                # For other namespaces, filter out all unauthenticated controllers
                unauthenticated_controllers = PermissionService.find_unauthenticated_controllers
                permissions_scope = permissions_scope.where.not(controller: unauthenticated_controllers) if unauthenticated_controllers.any?
              end
              
              @permissions = permissions_scope.order(:namespace, :controller, :action)
              @permissions_by_namespace = @permissions.group_by(&:namespace).transform_values do |perms|
                perms.group_by(&:controller)
              end
              
              # Get the count of active permissions for a more informative message
              permission_count = Hub::Admin::Permission.count
              flash.now[:notice] = "Successfully refreshed permissions. Found #{permission_count} system permissions."
              redirect_to hub_admin_permissions_path, notice: "Successfully refreshed permissions. Found #{permission_count} system permissions."
            end
          else
            # Send error notification
            Hub::NotificationService.notify(
              user: Current.user,
              message: "Failed to refresh permissions",
              notification_type: 'error'
            )
            
            format.html { redirect_to hub_admin_permissions_path, alert: 'Failed to refresh permissions.' }
            format.turbo_stream do
              flash.now[:alert] = 'Failed to refresh permissions.'
              redirect_to hub_admin_permissions_path, alert: 'Failed to refresh permissions.'
            end
          end
        end
      end
    end
    
    private
    
    # Private methods have been moved to PermissionService
  end
end
