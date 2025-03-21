# frozen_string_literal: true

module Hub
  module Admin
    # Background job to handle the processing of newly discovered controller actions
    # This job is triggered when a controller action is executed for the first time
    # or when a previously unknown action is executed
    class ProcessNewControllerActionJob < ApplicationJob
      queue_as :default

      # We don't want to process the same controller/action combo multiple times in parallel
      # so we use a unique lock based on the namespace, controller, and action
      discard_on ActiveJob::DeserializationError
      
      # Process a newly discovered controller action
      # @param namespace [String] the namespace of the controller
      # @param controller [String] the name of the controller
      # @param action [String] the name of the action
      # @param description [String] a human-readable description of the action
      def perform(namespace, controller, action, description)
        # Skip system controllers and actions that should not be tracked
        return if should_skip_processing?(namespace, controller, action)
        
        # Check if this permission already exists and is active
        permission = Hub::Admin::Permission.find_by(
          namespace: namespace,
          controller: controller,
          action: action
        )
        
        if permission.nil?
          # Create a new permission record
          create_new_permission(namespace, controller, action, description)
        elsif permission.status == 'archived'
          # Reactivate an archived permission
          reactivate_permission(permission, description)
        end
      end
      
      private
      
      # Check if we should skip processing this controller action
      def should_skip_processing?(namespace, controller, action)
        system_controllers = %w[application sessions passwords admin/system]
        system_actions = %w[authorize_namespace namespace_scope allowed_to? user_is_admin?]
        
        return true if system_controllers.include?(controller)
        return true if system_actions.include?(action)
        return true if controller.start_with?('public/') # Public controllers don't need permissions
        return true if action.start_with?('_') || action.include?('=') # Private/internal methods
        
        false
      end
      
      # Create a new permission record
      def create_new_permission(namespace, controller, action, description)
        permission = Hub::Admin::Permission.create!(
          namespace: namespace,
          controller: controller,
          action: action,
          description: description || generate_default_description(namespace, controller, action),
          status: 'active',
          discovered_at: Time.zone.now,
          discovery_method: 'automatic'
        )
        
        # Create an audit entry for the new permission
        Authorization::AuditService.permission_change(permission, 'created', 
          change_reason: 'Automatically discovered while in use')
        
        # Clear relevant caches
        Authorization::CacheService.clear_permission_caches(namespace, controller, action)
        
        # Log the discovery
        Rails.logger.info("Automatically discovered new permission: #{namespace}/#{controller}##{action}")
      end
      
      # Reactivate an archived permission
      def reactivate_permission(permission, description)
        # Store previous state for audit
        previous_state = {
          status: permission.status,
          description: permission.description,
          discovered_at: permission.discovered_at
        }
        
        # Update the permission
        permission.update!(
          status: 'active',
          description: description || permission.description,
          discovered_at: Time.zone.now,
          discovery_method: 'automatic'
        )
        
        # Create an audit entry for the reactivated permission
        Authorization::AuditService.permission_change(
          permission, 
          'reactivated', 
          previous_state: previous_state,
          change_reason: 'Automatically rediscovered while in use'
        )
        
        # Clear relevant caches
        Authorization::CacheService.clear_permission_caches(
          permission.namespace, 
          permission.controller, 
          permission.action
        )
        
        # Log the reactivation
        Rails.logger.info("Automatically reactivated permission: #{permission.namespace}/#{permission.controller}##{permission.action}")
      end
      
      # Generate a default description if none was provided
      def generate_default_description(namespace, controller, action)
        crud_actions = {
          'index' => 'View list of records',
          'show' => 'View details of a record',
          'new' => 'Access new record form',
          'create' => 'Create a new record',
          'edit' => 'Access edit record form',
          'update' => 'Update an existing record',
          'destroy' => 'Delete a record'
        }
        
        if crud_actions.key?(action)
          "#{crud_actions[action]} in #{namespace}/#{controller}"
        else
          "#{action.humanize} in #{namespace}/#{controller}"
        end
      end
    end
  end
end
