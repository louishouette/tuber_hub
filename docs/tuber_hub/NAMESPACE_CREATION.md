# Creating a New Namespace in TuberHub

This guide outlines the step-by-step process for creating a new namespace with its own CRUD MVCs in TuberHub. Follow these instructions to ensure your namespace integrates properly with the application architecture.

## Table of Contents

1. [Overview](#overview)
2. [Namespace Structure](#namespace-structure)
3. [Step-by-Step Guide](#step-by-step-guide)
   - [Step 1: Create the Namespace Controller](#step-1-create-the-namespace-controller)
   - [Step 2: Create the Base Controller](#step-2-create-the-base-controller)
   - [Step 3: Create the Dashboard Controller](#step-3-create-the-dashboard-controller)
   - [Step 4: Create CRUD Controllers](#step-4-create-crud-controllers)
   - [Step 5: Create Models](#step-5-create-models)
   - [Step 6: Create Views](#step-6-create-views)
   - [Step 7: Update Routes](#step-7-update-routes)
   - [Step 8: Update Navigation](#step-8-update-navigation)
   - [Step 9: Create Policies](#step-9-create-policies)
4. [Testing Your Namespace](#testing-your-namespace)
5. [Troubleshooting](#troubleshooting)

## Overview

TuberHub is organized into namespaces that represent different functional areas of the application. Each namespace follows a consistent structure with its own controllers, views, and routes. This modular approach helps maintain separation of concerns and makes the codebase more maintainable.

Existing namespaces include:
- `hub/admin` - Administrative functions
- `hub/core` - Core functionality
- `hub/cultivation` - Cultivation management
- `hub/measure` - Measurement and analytics

## Namespace Structure

A typical namespace in TuberHub follows this structure:

```
app/
  controllers/
    hub/
      your_namespace_controller.rb         # Namespace controller
      your_namespace/
        base_controller.rb                 # Base controller for the namespace
        dashboard_controller.rb            # Dashboard controller
        resource_controller.rb             # CRUD controllers for resources
  models/
    hub/
      your_namespace/
        resource.rb                        # Models for the namespace
  views/
    hub/
      your_namespace/
        dashboard/
          index.html.erb                   # Dashboard view
        resource/
          index.html.erb                   # Resource views
          show.html.erb
          new.html.erb
          edit.html.erb
          _form.html.erb
    layouts/
      hub/
        shared/
          sidebar/
            your_namespace/
              _menu.html.erb               # Sidebar menu for the namespace
  policies/
    hub/
      your_namespace/
        resource_policy.rb                 # Policies for the namespace
```

## Step-by-Step Guide

### Step 1: Create the Namespace Controller

Create a namespace controller in `app/controllers/hub/your_namespace_controller.rb`:

```ruby
# frozen_string_literal: true

module Hub
  # Controller for the YourNamespace namespace
  class YourNamespaceController < ApplicationController
    # This controller serves as a namespace controller
    # All your_namespace controllers should inherit from Hub::YourNamespace::BaseController
  end
end
```

### Step 2: Create the Base Controller

Create a base controller for your namespace in `app/controllers/hub/your_namespace/base_controller.rb`:

```ruby
# frozen_string_literal: true

module Hub
  module YourNamespace
    # Base controller for the YourNamespace namespace
    class BaseController < Hub::BaseController
      include NamespaceViewPath
      include FarmSelection  # If your namespace requires farm selection
      
      # Add any namespace-specific before_actions or methods here
    end
  end
end
```

### Step 3: Create the Dashboard Controller

Create a dashboard controller in `app/controllers/hub/your_namespace/dashboard_controller.rb`:

```ruby
# frozen_string_literal: true

module Hub
  module YourNamespace
    # Dashboard controller for the YourNamespace namespace
    class DashboardController < BaseController
      def index
        # Dashboard logic here
        @farm = Current.farm
        # Add any other instance variables needed for the dashboard
      end
    end
  end
end
```

### Step 4: Create CRUD Controllers

Create CRUD controllers for your resources in `app/controllers/hub/your_namespace/resources_controller.rb`:

```ruby
# frozen_string_literal: true

module Hub
  module YourNamespace
    # Controller for managing Resources in the YourNamespace namespace
    class ResourcesController < BaseController
      before_action :set_resource, only: [:show, :edit, :update, :destroy]
      
      # GET /hub/your_namespace/resources
      def index
        @resources = Hub::YourNamespace::Resource.for_current_farm
                                               .page(params[:page])
                                               .per(params[:per_page] || 10)
      end
      
      # GET /hub/your_namespace/resources/1
      def show
      end
      
      # GET /hub/your_namespace/resources/new
      def new
        @resource = Hub::YourNamespace::Resource.new
      end
      
      # GET /hub/your_namespace/resources/1/edit
      def edit
      end
      
      # POST /hub/your_namespace/resources
      def create
        @resource = Hub::YourNamespace::Resource.new(resource_params)
        @resource.farm = Current.farm
        
        if @resource.save
          redirect_to hub_your_namespace_resource_path(@resource), notice: 'Resource was successfully created.'
        else
          render :new
        end
      end
      
      # PATCH/PUT /hub/your_namespace/resources/1
      def update
        if @resource.update(resource_params)
          redirect_to hub_your_namespace_resource_path(@resource), notice: 'Resource was successfully updated.'
        else
          render :edit
        end
      end
      
      # DELETE /hub/your_namespace/resources/1
      def destroy
        @resource.destroy
        redirect_to hub_your_namespace_resources_path, notice: 'Resource was successfully destroyed.'
      end
      
      private
      
      # Use callbacks to share common setup or constraints between actions
      def set_resource
        @resource = Hub::YourNamespace::Resource.find(params[:id])
      end
      
      # Only allow a list of trusted parameters through
      def resource_params
        params.expect(:resource).permit(:name, :description, :other_attributes)
      end
    end
  end
end
```

### Step 5: Create Models

Create models for your namespace in `app/models/hub/your_namespace/resource.rb`:

```ruby
# frozen_string_literal: true

module Hub
  module YourNamespace
    # Model for resources in the YourNamespace namespace
    class Resource < ApplicationRecord
      include FarmScoped
      
      # Associations
      belongs_to :farm, class_name: 'Hub::Admin::Farm'
      
      # Validations
      validates :name, presence: true
      
      # Scopes
      scope :active, -> { where(active: true) }
      
      # Add any other model-specific methods or scopes here
    end
  end
end
```

Create the migration for your model:

```bash
rails generate migration CreateHubYourNamespaceResources name:string description:text farm:references active:boolean
```

### Step 6: Create Views

Create the necessary view files for your namespace:

1. Dashboard view in `app/views/hub/your_namespace/dashboard/index.html.erb`:

```erb
<div class="p-4 bg-white border border-gray-200 rounded-lg shadow-sm 2xl:col-span-2 dark:border-gray-700 sm:p-6 dark:bg-gray-800">
  <div class="flex items-center justify-between mb-4">
    <h3 class="text-xl font-bold leading-none text-gray-900 dark:text-white">YourNamespace Dashboard</h3>
  </div>
  
  <div class="flow-root">
    <!-- Dashboard content here -->
    <p>Welcome to the YourNamespace dashboard for <%= @farm&.name %>.</p>
    
    <!-- Add dashboard widgets, charts, or other content here -->
  </div>
</div>
```

2. Resource index view in `app/views/hub/your_namespace/resources/index.html.erb`:

```erb
<div class="p-4 bg-white border border-gray-200 rounded-lg shadow-sm 2xl:col-span-2 dark:border-gray-700 sm:p-6 dark:bg-gray-800">
  <div class="flex items-center justify-between mb-4">
    <h3 class="text-xl font-bold leading-none text-gray-900 dark:text-white">Resources</h3>
    <%= link_to new_hub_your_namespace_resource_path, class: "text-sm font-medium text-blue-600 hover:bg-gray-100 dark:text-blue-500 dark:hover:bg-gray-700 rounded-lg p-2" do %>
      <%= icon "plus", class: "w-5 h-5 inline" %> New Resource
    <% end %>
  </div>
  
  <div class="flow-root">
    <table class="min-w-full divide-y divide-gray-200 dark:divide-gray-600">
      <thead class="bg-gray-100 dark:bg-gray-700">
        <tr>
          <th scope="col" class="p-4 text-left text-xs font-medium text-gray-500 uppercase dark:text-gray-400">Name</th>
          <th scope="col" class="p-4 text-left text-xs font-medium text-gray-500 uppercase dark:text-gray-400">Description</th>
          <th scope="col" class="p-4 text-left text-xs font-medium text-gray-500 uppercase dark:text-gray-400">Status</th>
          <th scope="col" class="p-4 text-right text-xs font-medium text-gray-500 uppercase dark:text-gray-400">Actions</th>
        </tr>
      </thead>
      <tbody class="bg-white divide-y divide-gray-200 dark:bg-gray-800 dark:divide-gray-700">
        <% @resources.each do |resource| %>
          <tr class="hover:bg-gray-100 dark:hover:bg-gray-700">
            <td class="p-4 text-sm font-normal text-gray-900 whitespace-nowrap dark:text-white"><%= resource.name %></td>
            <td class="p-4 text-sm font-normal text-gray-500 whitespace-nowrap dark:text-gray-400"><%= resource.description %></td>
            <td class="p-4 text-sm font-normal text-gray-500 whitespace-nowrap dark:text-gray-400">
              <% if resource.active? %>
                <span class="bg-green-100 text-green-800 text-xs font-medium mr-2 px-2.5 py-0.5 rounded-full dark:bg-green-900 dark:text-green-300">Active</span>
              <% else %>
                <span class="bg-red-100 text-red-800 text-xs font-medium mr-2 px-2.5 py-0.5 rounded-full dark:bg-red-900 dark:text-red-300">Inactive</span>
              <% end %>
            </td>
            <td class="p-4 text-sm font-normal text-right whitespace-nowrap">
              <%= link_to hub_your_namespace_resource_path(resource), class: "text-blue-600 hover:underline dark:text-blue-500" do %>
                <%= icon "eye", class: "w-5 h-5 inline" %>
              <% end %>
              <%= link_to edit_hub_your_namespace_resource_path(resource), class: "text-blue-600 hover:underline dark:text-blue-500 ml-2" do %>
                <%= icon "pencil", class: "w-5 h-5 inline" %>
              <% end %>
              <%= link_to hub_your_namespace_resource_path(resource), method: :delete, data: { confirm: 'Are you sure?' }, class: "text-red-600 hover:underline dark:text-red-500 ml-2" do %>
                <%= icon "trash", class: "w-5 h-5 inline" %>
              <% end %>
            </td>
          </tr>
        <% end %>
      </tbody>
    </table>
    
    <div class="mt-4">
      <%= paginate @resources %>
    </div>
  </div>
</div>
```

3. Create other views for show, new, edit, and _form partials following the same pattern.

### Step 7: Update Routes

Update the routes in `config/routes.rb` to include your namespace:

```ruby
Rails.application.routes.draw do
  # Existing routes...
  
  namespace :hub do
    # Existing namespaces...
    
    # Your new namespace
    namespace :your_namespace do
      get '/', to: 'dashboard#index', as: :dashboard
      resources :resources
      # Add other resource routes as needed
    end
  end
end
```

### Step 8: Update Navigation

1. Update the sidebar detection in `app/views/layouts/hub/shared/_sidebar.html.erb` to include your namespace:

```erb
<% 
  # Determine the current namespace based on controller path
  namespace = "core"
  if controller.controller_path.start_with?('hub/admin')
    namespace = "admin"
  elsif controller.controller_path.start_with?('hub/cultivation')
    namespace = "cultivation"
  elsif controller.controller_path.start_with?('hub/measure')
    namespace = "measure"
  elsif controller.controller_path.start_with?('hub/your_namespace')
    namespace = "your_namespace"
  elsif controller.controller_path.start_with?('hub/core')
    namespace = "core"
  end
%>
```

2. Add your namespace to the namespace_titles and namespace_icons hashes:

```erb
<% namespace_titles = {
   "admin" => "Admin", 
   "core" => "Core", 
   "cultivation" => "Cultivation", 
   "measure" => "Measure",
   "your_namespace" => "Your Namespace"
} %>
<% namespace_icons = {
   "admin" => "shield-check", 
   "core" => "home-modern", 
   "cultivation" => "beaker", 
   "measure" => "chart-bar",
   "your_namespace" => "your-icon-name"
} %>
```

3. Create a sidebar menu for your namespace in `app/views/layouts/hub/shared/sidebar/your_namespace/_menu.html.erb`:

```erb
<ul class="space-y-2">
  <!-- Dashboard -->
  <li>
    <a
      href="<%= hub_your_namespace_dashboard_path rescue "#" %>"
      class="flex items-center p-2 text-base font-medium text-gray-900 rounded-lg dark:text-white hover:bg-gray-100 dark:hover:bg-gray-700 group <%= 'bg-blue-50 dark:bg-gray-600' if controller.controller_name == 'dashboard' %>"
    >
      <%= icon "your-icon-name", class: "w-6 h-6 text-gray-500 transition duration-75 dark:text-gray-400 group-hover:text-gray-900 dark:group-hover:text-white" %>
      <span class="ml-3">Dashboard</span>
    </a>
  </li>
  
  <!-- Resources -->
  <li>
    <a
      href="<%= hub_your_namespace_resources_path rescue "#" %>"
      class="flex items-center p-2 text-base font-medium text-gray-900 rounded-lg dark:text-white hover:bg-gray-100 dark:hover:bg-gray-700 group <%= 'bg-blue-50 dark:bg-gray-600' if controller.controller_name == 'resources' %>"
    >
      <%= icon "document", class: "w-6 h-6 text-gray-500 transition duration-75 dark:text-gray-400 group-hover:text-gray-900 dark:group-hover:text-white" %>
      <span class="ml-3">Resources</span>
    </a>
  </li>
  
  <!-- Add more menu items as needed -->
</ul>
```

### Step 9: Create Policies

Create policies for your namespace resources in `app/policies/hub/your_namespace/resource_policy.rb`:

```ruby
# frozen_string_literal: true

module Hub
  module YourNamespace
    # Policy for Resource model
    class ResourcePolicy < ApplicationPolicy
      # Define who can access the index action
      def index?
        user_has_farm_access?
      end
      
      # Define who can view a resource
      def show?
        user_has_farm_access?
      end
      
      # Define who can create a new resource
      def create?
        user_has_farm_access?
      end
      
      # Define who can update a resource
      def update?
        user_has_farm_access?
      end
      
      # Define who can delete a resource
      def destroy?
        user_has_farm_access?
      end
      
      private
      
      # Check if the user has access to the farm
      def user_has_farm_access?
        return false unless Current.farm.present?
        user.farms.exists?(id: Current.farm.id)
      end
      
      # Define which attributes can be mass-assigned for which roles
      class Scope < Scope
        def resolve
          if user.admin?
            scope.all
          else
            scope.for_current_farm
          end
        end
      end
    end
  end
end
```

## Testing Your Namespace

After creating all the necessary files, test your namespace by:

1. Running the migrations: `rails db:migrate`
2. Starting the server: `bin/dev`
3. Navigating to your namespace: `http://localhost:3000/hub/your_namespace`

Ensure that:
- The dashboard loads correctly
- The sidebar shows your namespace
- CRUD operations work for your resources
- Authorization policies are enforced correctly

## Troubleshooting

### Common Issues

1. **Zeitwerk Autoloading Errors**: Ensure your file names match the class names and follow the proper module nesting pattern.

   ```
   Error: expected file app/controllers/hub/your_namespace_controller.rb to define constant Hub::YourNamespaceController
   ```

   Solution: Check that your file defines the correct class with the proper module nesting.

2. **Routing Errors**: Ensure your routes are properly defined and namespaced.

   ```
   No route matches [GET] "/hub/your_namespace"
   ```

   Solution: Check your routes.rb file and ensure the namespace and routes are properly defined.

3. **Missing Template Errors**: Ensure your view templates are in the correct location.

   ```
   Missing template hub/your_namespace/dashboard/index
   ```

   Solution: Check that your view files are in the correct directory and have the correct names.

4. **Authorization Errors**: Ensure your policies are properly defined and the user has the necessary permissions.

   ```
   Pundit::NotAuthorizedError
   ```

   Solution: Check your policy files and ensure the user has the necessary permissions to access the resource.

### Debugging Tips

1. Use `rails routes | grep your_namespace` to check if your routes are properly defined.
2. Use `rails c` to test your models and policies in the console.
3. Check the Rails logs for detailed error messages.
4. Use `binding.pry` or `debugger` to debug your code at specific points.

---

By following this guide, you should be able to create a new namespace with its own CRUD MVCs in TuberHub. If you encounter any issues, refer to the troubleshooting section or check the existing namespaces for reference.
