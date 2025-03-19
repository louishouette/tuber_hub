# TuberHub Controllers Architecture

## Controller Inheritance Hierarchy

The TuberHub application follows a consistent controller inheritance pattern to maintain organization, reuse code, and ensure proper layout application across the different application namespaces.

```
ApplicationController
  └── HubController (layout 'hub/application')
      └── Hub::BaseController
          ├── Hub::Admin::BaseController
          │   └── Hub::Admin::UsersController (and other admin controllers)
          └── Hub::Core::BaseController
              └── Hub::Core::FarmsController (and other core controllers)
```

## Creating New Namespaces

When creating a new namespace within the TuberHub application, follow these guidelines:

1. **Always create a BaseController** for your namespace that inherits from the appropriate parent controller
2. **Ensure all controllers** in that namespace inherit from the namespace's BaseController
3. **Follow the module nesting pattern** to maintain consistent namespacing

### Example: Creating a new 'Reports' namespace

```ruby
# app/controllers/hub/reports/base_controller.rb
module Hub
  module Reports
    class BaseController < Hub::BaseController
      before_action :set_default_view_path
      
      private
      
      # Set the default view path to include the namespace
      def set_default_view_path
        prepend_view_path Rails.root.join('app', 'views', 'hub', 'reports')
      end
    end
  end
end
```

```ruby
# app/controllers/hub/reports/sales_controller.rb
module Hub
  module Reports
    class SalesController < BaseController
      # Controller actions
    end
  end
end
```

## Benefits of This Approach

1. **Consistent Layout Application**: All namespaced controllers inherit the correct layout
2. **Centralized Authorization**: Each namespace can implement its own authorization logic in the BaseController
3. **DRY Code**: Shared functionality can be placed in the appropriate BaseController
4. **Clear Organization**: The inheritance hierarchy clearly communicates the application's structure

## Namespace-Specific Functionality

### HubController
- Provides the base layout for all authenticated hub pages
- Requires authentication for all hub pages by default

### Hub::BaseController
- Handles authorization for namespace-specific resources
- Provides the `authorize_namespace_access` method

### Hub::Admin::BaseController
- Restricts access to admin users only
- Sets custom view paths for admin views

### Hub::Core::BaseController
- Sets default view paths for core functionality
- Provides common functionality for core features

## Adding New Namespaces

When adding a new top-level namespace to the application, consider the following:

1. Create a new layout if needed, or inherit from an existing one
2. Create a BaseController that inherits from the appropriate parent controller
3. Implement namespace-specific authorization in the BaseController
4. Create policy classes for the new namespace's resources
5. Document the new namespace's purpose and structure in this guide
