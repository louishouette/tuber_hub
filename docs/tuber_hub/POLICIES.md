# TuberHub Policies Structure and Guidelines

## Overview

This document outlines the structure, organization, and implementation guidelines for Pundit policies in TuberHub. Policies are a critical component of TuberHub's authorization system, providing object-level authorization checks that complement the role-based access control system.

## Policy Directory Structure

TuberHub policies should follow a consistent directory structure that mirrors the application's namespace organization. The standard structure is:

```
app/policies/
  application_policy.rb         # Base policy all others inherit from
  namespace_policy.rb           # Base policy for namespaced controllers
  concerns/
    permission_policy_concern.rb # Shared policy functionality
  hub/
    admin_policy.rb             # Namespace-level policy
    admin/
      base_policy.rb            # Base policy for the namespace
      resource_policy.rb        # Resource-specific policies
    core_policy.rb
    core/
      resource_policy.rb
    cultivation_policy.rb
    cultivation/
      resource_policy.rb
    measure_policy.rb
    measure/
      resource_policy.rb
```

### Key Components

1. **Application Policy**: The root policy class that all other policies inherit from.
2. **Namespace Policy**: Provides shared functionality for all namespaced policies.
3. **Namespace-Level Policies**: Policies for namespace controllers (e.g., `Hub::AdminController`).
4. **Resource-Specific Policies**: Policies for specific resources within a namespace.

## Policy Naming Conventions

Policies should follow these naming conventions:

1. **Class Names**: `{Resource}Policy` (e.g., `UserPolicy`, `FarmPolicy`)
2. **File Names**: `{resource}_policy.rb` (e.g., `user_policy.rb`, `farm_policy.rb`)
3. **Namespace Policies**: `{Namespace}Policy` (e.g., `AdminPolicy`, `CorePolicy`)

## Policy Implementation Guidelines

### Basic Policy Structure

```ruby
# frozen_string_literal: true

module Hub
  module Admin
    # Policy for Hub::Admin::User resource
    class UserPolicy < BasePolicy
      def index?
        user_can?(:index, 'users', 'hub/admin')
      end

      def show?
        user_can?(:show, 'users', 'hub/admin')
      end

      def create?
        user_can?(:create, 'users', 'hub/admin')
      end

      def update?
        user_can?(:update, 'users', 'hub/admin')
      end

      def destroy?
        user_can?(:destroy, 'users', 'hub/admin')
      end

      class Scope < Scope
        def resolve
          if user_can?(:index, 'users', 'hub/admin')
            scope.all
          else
            scope.none
          end
        end
      end
    end
  end
end
```

### Namespace Base Policy

```ruby
# frozen_string_literal: true

module Hub
  module Admin
    # Base policy for the Admin namespace
    class BasePolicy < ApplicationPolicy
      # Add namespace-specific policy methods here
    end
  end
end
```

### Farm-Scoped Policies

For policies that require farm-level authorization:

```ruby
# frozen_string_literal: true

module Hub
  module Core
    # Policy for Hub::Core::Crop resource
    class CropPolicy < BasePolicy
      def show?
        user_can?(:show, 'crops', 'hub/core', farm: record.farm)
      end

      def update?
        user_can?(:update, 'crops', 'hub/core', farm: record.farm)
      end

      class Scope < Scope
        def resolve
          if user_can?(:index, 'crops', 'hub/core')
            scope.for_current_farm
          else
            scope.none
          end
        end
      end
    end
  end
end
```

## Integration with Authorization System

Policies in TuberHub integrate with the broader authorization system through the `PermissionPolicyConcern`, which provides the following methods:

- `user_can?(action, controller, namespace, farm: nil)`: Checks if the user has permission for a specific action
- `user_has_role?(role_name, farm: nil)`: Checks if the user has a specific role
- `user_has_any_role?(role_names, farm: nil)`: Checks if the user has any of the specified roles

These methods delegate to the `AuthorizationService` which handles permission checks, caching, and auditing.

## Policy Scope Usage

Policy scopes filter collections based on user permissions:

```ruby
# In controllers
@users = policy_scope(Hub::Admin::User)

# With namespace scoping
@crops = namespace_scope(Hub::Core::Crop, namespace: 'hub/core', controller: 'crops')

# With farm scoping
@crops = namespace_scope(Hub::Core::Crop, namespace: 'hub/core', controller: 'crops', farm: Current.farm)
```

## Best Practices

1. **Follow the Directory Structure**: Maintain the namespace hierarchy in policy organization.
2. **Use the Permission Policy Concern**: Leverage the existing authorization infrastructure.
3. **Keep Policies Simple**: Focus on delegating to the authorization service rather than complex logic.
4. **Document Special Cases**: Add comments for non-standard authorization rules.
5. **Consider Farm Context**: Always include farm context for farm-scoped resources.
6. **Use Policy Scopes**: Filter collections using policy scopes rather than manual filtering.
7. **Test Policies**: Ensure policies are covered by tests, especially for critical resources.

## Refactoring Existing Policies

To address inconsistencies in the current policy structure:

1. **Identify Misplaced Policies**: Locate policies that don't follow the namespace structure.
2. **Create Missing Directories**: Ensure each namespace has its appropriate directory.
3. **Move Policies to Correct Locations**: Relocate policies to match the namespace hierarchy.
4. **Update References**: Ensure all policy references in controllers are updated.
5. **Remove Duplicates**: Eliminate duplicate policy files after confirming the correct version.

## Troubleshooting

### Common Policy Issues

1. **Unauthorized Access**: 
   - Verify the policy method returns `true` for the action
   - Check that the user has the required permission
   - Ensure the farm context is correctly passed for farm-scoped resources

2. **Scope Returns No Records**:
   - Verify the scope method is correctly implemented
   - Check that the user has the required index permission
   - For farm-scoped resources, ensure Current.farm is set

3. **Policy Not Found**:
   - Ensure the policy is in the correct namespace
   - Check that the policy class name matches the resource class name
   - Verify the policy file is in the correct directory

## Creating New Policies

When creating new resources, manually create policy files following the established structure and naming conventions. Ensure the policy is placed in the correct namespace directory and includes the standard CRUD methods as needed.
