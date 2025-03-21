# frozen_string_literal: true

module Hub
  module Authorization
    # Generator for creating controllers with proper authorization integration
    class ControllerGenerator < Rails::Generators::Base
      source_root File.expand_path('templates', __dir__)
      
      argument :namespace, type: :string, desc: 'The namespace for the controller (e.g., admin, user)'
      argument :controller_name, type: :string, desc: 'The name of the controller to create'
      class_option :actions, type: :array, default: %w[index show new create edit update destroy], 
                 desc: 'The actions to include in the controller'
      class_option :skip_view, type: :boolean, default: false, 
                 desc: 'Skip generation of view templates'
      class_option :farm_scoped, type: :boolean, default: false, 
                 desc: 'Whether the controller should be scoped to farms'
                 
      def create_controller_file
        @namespace = namespace.underscore
        @controller = controller_name.underscore
        @actions = options[:actions]
        @farm_scoped = options[:farm_scoped]
        @resource_name = @controller.singularize
        @resource_class = @resource_name.camelize
        
        # Create directory if it doesn't exist
        target_dir = "app/controllers/#{@namespace}"
        empty_directory(target_dir) unless File.directory?(target_dir)
        
        # Create the controller
        template 'controller.rb.tt', File.join(target_dir, "#{@controller}_controller.rb")
      end
      
      def create_views
        return if options[:skip_view]
        
        @namespace = namespace.underscore
        @controller = controller_name.underscore
        @resource_name = @controller.singularize
        @resource_class = @resource_name.camelize
        @farm_scoped = options[:farm_scoped]
        
        # Create view directory
        view_dir = "app/views/#{@namespace}/#{@controller}"
        empty_directory(view_dir) unless File.directory?(view_dir)
        
        # Create view templates for each action
        if options[:actions].include?('index')
          template 'views/index.html.erb.tt', File.join(view_dir, 'index.html.erb')
        end
        
        if options[:actions].include?('show')
          template 'views/show.html.erb.tt', File.join(view_dir, 'show.html.erb')
        end
        
        if options[:actions].include?('new') || options[:actions].include?('create')
          template 'views/new.html.erb.tt', File.join(view_dir, 'new.html.erb')
        end
        
        if options[:actions].include?('edit') || options[:actions].include?('update')
          template 'views/edit.html.erb.tt', File.join(view_dir, 'edit.html.erb')
        end
        
        if options[:actions].include?('new') || options[:actions].include?('edit')
          template 'views/_form.html.erb.tt', File.join(view_dir, '_form.html.erb')
        end
      end
      
      def create_policy
        @namespace = namespace.underscore
        @controller = controller_name.underscore
        @resource_name = @controller.singularize
        @resource_class = @resource_name.camelize
        @farm_scoped = options[:farm_scoped]
        
        # Create policy class
        policy_dir = "app/policies/#{@namespace}"
        empty_directory(policy_dir) unless File.directory?(policy_dir)
        
        template 'policy.rb.tt', File.join(policy_dir, "#{@resource_name}_policy.rb")
      end
      
      def add_route
        @namespace = namespace.underscore
        @controller = controller_name.underscore
        
        # Add route to routes.rb file
        route_file = 'config/routes.rb'
        inject_into_file route_file, after: "Rails.application.routes.draw do\n" do
          "  namespace :#{@namespace} do\n    resources :#{@controller}\n  end\n"
        end
      end
      
      def register_permissions
        @namespace = namespace.underscore
        @controller = controller_name.underscore
        
        say "Registering permissions for #{@namespace}/#{@controller}...", :green
        say "Remember to run 'rails generate hub:authorization:refresh' to update permissions", :yellow
      end
    end
  end
end
