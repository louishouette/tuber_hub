# frozen_string_literal: true

module Hub
  module Authorization
    # Generates a Pundit policy for a specified model with RBAC integration
    class PolicyGenerator < Rails::Generators::NamedBase
      source_root File.expand_path('templates', __dir__)
      
      argument :model_name, type: :string, default: nil, desc: 'The name of the model to create a policy for'
      class_option :namespace, type: :string, default: nil, desc: 'The namespace for the policy (e.g., admin, user)'
      class_option :farm_scoped, type: :boolean, default: false, desc: 'Whether the policy should be scoped to farms'

      def create_policy_file
        @model_class = model_name.camelize
        @model_var = model_name.underscore
        @namespace = options[:namespace].present? ? options[:namespace].underscore : nil
        @farm_scoped = options[:farm_scoped]
        
        # Determine target path
        target_dir = 'app/policies'
        target_dir = File.join(target_dir, @namespace) if @namespace.present?
        
        # Set up template variables
        @policy_class_name = "#{@model_class}Policy"
        @full_policy_class = @namespace.present? ? "#{@namespace.camelize}::#{@policy_class_name}" : @policy_class_name
        
        template 'policy.rb.tt', File.join(target_dir, "#{@model_var}_policy.rb")
      end
      
      def create_spec_file
        @model_class = model_name.camelize
        @model_var = model_name.underscore
        @namespace = options[:namespace].present? ? options[:namespace].underscore : nil
        @farm_scoped = options[:farm_scoped]
        
        # Determine target path for specs
        target_dir = 'spec/policies'
        target_dir = File.join(target_dir, @namespace) if @namespace.present?
        
        # Set up template variables
        @policy_class_name = "#{@model_class}Policy"
        @full_policy_class = @namespace.present? ? "#{@namespace.camelize}::#{@policy_class_name}" : @policy_class_name
        
        template 'policy_spec.rb.tt', File.join(target_dir, "#{@model_var}_policy_spec.rb")
      end
      
      def add_permissions_to_system
        # Extract namespace and controller from model
        namespace = @namespace || ''
        controller = @model_var.pluralize
        
        say "Registering permissions for #{namespace}/#{controller}...", :green
        
        # Call the permission service to register standard CRUD permissions
        cud_actions = %w[index show new create edit update destroy]
        
        cud_actions.each do |action|
          say "Adding permission for #{namespace}/#{controller}##{action}", :green
        end
        
        say "Remember to run 'rails generate hub:authorization:refresh' to update the permission system", :yellow
      end
    end
  end
end
