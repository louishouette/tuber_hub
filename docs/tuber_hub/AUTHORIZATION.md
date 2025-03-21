# TuberHub Authorization System Documentation

## Overview

TuberHub employs a sophisticated role-based access control (RBAC) system built on top of the Pundit gem. This document explains how authorization works throughout the application, from user roles and permissions to controller-level authorization checks.

## Core Components

### 1. Users, Roles, and Permissions

- **User**: A user in the system who needs access to various resources.
- **Role**: A collection of permissions that can be assigned to users (e.g., Admin, Manager, Viewer).
- **Permission**: A specific action allowed on a controller (e.g., `hub/admin/users#create`).
- **Role Assignment**: Associates a role with a user (with optional expiration).
- **Permission Assignment**: Associates a permission with a role (with optional expiration).

### 2. Key Classes

#### Models
- `Hub::Admin::User`: The user model that includes authentication and role-based capabilities.
- `Hub::Admin::Role`: Defines roles that can be assigned to users.
- `Hub::Admin::Permission`: Represents allowed actions on specific controllers.
- `Hub::Admin::RoleAssignment`: Links users to roles (with optional farm-specific context).
- `Hub::Admin::PermissionAssignment`: Links roles to permissions (with optional expiration).

#### Services
- `AuthorizationService`: Main facade service that provides a unified interface to all authorization functionality.
- `Authorization::BaseService`: Provides shared constants and base functionality.
- `Authorization::QueryService`: Handles permission checks and user authorization queries.
- `Authorization::ManagementService`: Manages permission discovery and maintenance.
- `Authorization::CacheService`: Handles permission cache management and invalidation.

#### Concerns
- `AuthorizationConcern`: For controllers, provides authorization helpers like `user_can?` and `authorize_action!`.
- `PermissionPolicyConcern`: For Pundit policies, integrates with the permission system.

## Authorization Flow

1. When a request comes in, `ApplicationController` checks if the current user is authorized for the requested action.
2. The authorization check is handled through the following flow:
   - The controller calls Pundit's `authorize` method or uses helpers from `AuthorizationConcern`
   - Pundit policies leverage `PermissionPolicyConcern` which delegates to `AuthorizationService`
   - `AuthorizationService` delegates to `Authorization::QueryService` for permission checks
   - Permissions are checked against the database, with results cached for performance
3. Authorization may be skipped for certain controllers (public pages, authentication controllers).
4. Admin users automatically have access to all resources.

## Integration with Rails 8 Authentication

TuberHub's authorization system integrates seamlessly with the Rails 8 authentication framework:

1. **Current-Based Access**: Authorization checks use the `Current.user` object provided by the authentication system to determine the current user's permissions.

2. **Authentication-First Flow**: The authentication system runs first to establish user identity before any authorization checks are performed.

3. **Skip Authorization for Authentication Controllers**: The authorization system recognizes and skips authorization checks for authentication-related controllers, ensuring a smooth login/logout experience.

4. **Pundit Integration**: Pundit's `pundit_user` method has been configured to use `Current.user`, establishing a clean interface between the authentication and authorization systems.

## Permission Management

The system dynamically discovers and manages permissions based on the application's controllers and actions:

### Permission Discovery

1. The `AuthorizationService.discover_permissions` method (delegating to `Authorization::ManagementService`) scans all controllers in the application.
2. For each controller that requires authentication, it extracts:   
   - The namespace (e.g., `hub/admin`)
   - The controller name (e.g., `users`)
   - Available actions (e.g., `index`, `show`, `create`)
3. Permissions are created in the database with standard format and user-friendly descriptions.
4. Unused permissions (those no longer existing in the application) are automatically archived.

### Permission Refresh

To refresh all permissions in the system (discover new ones and archive unused ones):

```ruby
AuthorizationService.refresh_permissions
```

This is typically run during deployment or when significant controller changes occur.

### Permission Assignment

Administrators can assign permissions to roles through the admin interface:

1. Navigate to the role management section (hub/admin/roles).
2. Select a role and go to 'Assign Permissions'.
3. Choose from the available permissions, organized by namespace and controller.
4. Optionally set expiration dates for temporary permissions.

## User Role Management

Administrators can assign roles to users:

1. Navigate to the user management section (hub/admin/users).
2. Select a user and go to 'Assign Roles'.
3. Choose from available roles.
4. Optionally set expiration dates for temporary role assignments.

## Programmatic Authorization

### In Controllers

Authorization in controllers is handled through the `AuthorizationConcern`:  

```ruby
# Standard Pundit approach for model-based authorization
authorize @user

# For direct permission checks
user_can?(:create, 'users', 'hub/admin')

# For enforcing permission checks that raise exceptions
authorize_action!(:create, 'users', 'hub/admin')

# For farm-specific permissions
user_can?(:create, 'users', 'hub/admin', farm: @farm)

# For checking a user's ability to access a feature
feature_enabled_for_user?(:some_feature)
```

### In Views and Helpers

The `allowed_to?` helper method checks if a user has permission:  

```ruby
# Check if user can update a specific resource
allowed_to?(:update, @post)

# Check if user can access a namespace/controller action
allowed_to?(:create, { namespace: 'hub/admin', controller: 'users' })
```

### Scoping Collections

For index actions, collections can be scoped based on permissions:  

```ruby
@users = policy_scope(User)

# For namespace-based scoping
@users = namespace_scope(User, namespace: 'hub/admin', controller: 'users')
```

## Special Authorization Cases

### Public Controllers

Some controllers are exempt from authorization checks:

- Home/static pages  
- Controllers in the 'public' namespace
- Controllers that explicitly skip authentication

### Admin Users

Users with the 'admin' role bypass normal permission checks and have access to all resources.

### Farm-Level Authorization

TuberHub supports farm-scoped permissions and roles, allowing different access levels for users across different farms:

#### Farm-Specific Roles

- **Global Roles**: Apply across the entire application with `global=true` and `farm_id=nil`
- **Farm-Specific Roles**: Apply only to specific farms with `global=false` and a specific `farm_id`

#### Checking Farm-Specific Permissions

In controllers and views, you can check farm-specific permissions:  

```ruby
# Check if user can perform an action in the context of a specific farm
Current.user.can?(:manage, 'hub/admin', 'tubers', farm: @farm)

# Or using the allowed_to? helper
allowed_to?(:manage, { namespace: 'hub/admin', controller: 'tubers', farm: @farm })

# In a controller when using authorize_namespace
authorize_namespace(farm: @farm)

# With namespace_scope for filtering collections based on permissions
@crops = namespace_scope(Crop, farm: @farm)
```

#### Farm Role Assignment

Administrators can assign farm-specific roles to users:

1. Navigate to the farm management section (hub/admin/farms)
2. Select a farm and go to 'Manage Users'
3. Assign farm-specific roles to users
4. Optionally set expiration dates for temporary role assignments

#### Permission Resolution Logic

When checking permissions in a farm context:

1. The system checks if the user has **global roles** that grant the permission
2. The system also checks if the user has **farm-specific roles** that grant the permission
3. If either check passes, the user has permission

When checking permissions without a farm context (global context):

1. Only **global roles** are considered
2. **Farm-specific roles** are ignored

#### Checking Farm Roles Directly

You can check if a user has a specific role for a farm:

```ruby
# Check if user has the "Farm Manager" role for a specific farm
user.has_farm_role?("Farm Manager", @farm)
```

## Cache Management

For performance reasons, permission checks are cached:  

- User permission results are cached for 1 hour
- Farm-specific permission results are cached separately
- Permission groups are cached for 15 minutes
- Available namespaces are cached for 1 hour

The cache is managed through the `Authorization::CacheService` and accessed via the `AuthorizationService` facade:

```ruby
# Clear all caches
AuthorizationService.clear_all_permission_caches

# Clear user-specific caches
AuthorizationService.clear_user_permission_caches(user, farm: nil)

# Clear caches for a specific permission
AuthorizationService.clear_permission_caches('hub/admin', 'users', 'create')

# Clear caches related to a role assignment change
AuthorizationService.clear_role_assignment_caches(role_assignment)

# Clear caches related to a permission assignment change
AuthorizationService.clear_permission_assignment_caches(permission_assignment)
```

These methods are called automatically when permissions are updated, roles are changed, or user-role assignments are modified.

## Best Practices

1. **Always use the provided helpers** (`allowed_to?`, `authorize_namespace`) for authorization checks.
2. **Don't hardcode authorization logic** in controllers or views; use the permission system instead.
3. **Regularly refresh permissions** to ensure they stay synchronized with the application's controllers.
4. **Use time-limited roles and permissions** for temporary access requirements.
5. **Check authorization in every controller action** unless it explicitly doesn't require it.

## Technical Implementation Details

### Permission Format

Permissions follow a standardized format: `namespace/controller#action`

Examples:
- `hub/admin/users#create` (Create users in the admin section)
- `hub/core/farms#update` (Update farms in the core section)

### Database Schema

The authorization system uses several interconnected tables:

- `hub_admin_users`: Stores user information
- `hub_admin_roles`: Defines available roles
- `hub_admin_permissions`: Stores permissions with namespace/controller/action
- `hub_admin_role_assignments`: Links users to roles
- `hub_admin_permission_assignments`: Links roles to permissions

### Cache Management

To improve performance, the system uses caching extensively, managed by `Authorization::CacheService`:

```ruby
# For global permissions
Rails.cache.fetch("user_#{user.id}_permission_#{namespace}:#{controller}:#{action}", expires_in: 1.hour) do
  # Permission check logic
end

# For farm-specific permissions
Rails.cache.fetch("user_#{user.id}_farm_#{farm.id}_permission_#{namespace}:#{controller}:#{action}", expires_in: 1.hour) do
  # Farm-specific permission check logic
end
```

To avoid N+1 queries when checking multiple permissions for a user, the system supports permission preloading:

```ruby
# Preload global permissions for a user
AuthorizationService.preload_user_permissions(user)

# Preload farm-specific permissions
AuthorizationService.preload_user_permissions(user, farm: @farm)

# Check permissions using preloaded data (faster)
AuthorizationService.user_has_permission?(user, namespace, controller, action, use_preloaded: true)

# Check farm-specific permissions using preloaded data
AuthorizationService.user_has_permission?(user, namespace, controller, action, farm: @farm, use_preloaded: true)
```

This approach significantly reduces database queries in pages that perform multiple permission checks.

## Permission Auditing

The system includes a comprehensive audit trail for tracking changes to permissions:

### Audit Records

All permission changes are automatically logged in the `hub_admin_permission_audits` table, tracking:

- What permission changed (namespace/controller/action)
- What type of change occurred (created, updated, archived, restored, deleted)
- Who made the change (user or system)
- When the change occurred
- Previous state (for updates)

### Audit Types

The system tracks these types of changes:

- **created**: When a new permission is discovered
- **updated**: When an existing permission is modified
- **archived**: When a permission is marked as no longer in use
- **restored**: When an archived permission is made active again
- **deleted**: When a permission is permanently removed

### Querying Audit History

To retrieve permission history:

```ruby
# Get history for a specific permission
AuthorizationService.permission_history(permission)

# Get history for a namespace
AuthorizationService.namespace_history('hub/admin')

# Get history for a controller
AuthorizationService.controller_history('hub/admin', 'users')

# Get recent changes across the system
AuthorizationService.recent_changes(limit: 100)

# Get change statistics
AuthorizationService.change_statistics(days: 30)
```

### Automatic Auditing

Audit records are automatically created during these operations:

- Permission discovery (recording new or updated permissions)
- Permission archival (when permissions are no longer found in the codebase)
- Manual permission changes through the admin interface

## Troubleshooting

### Common Issues

1. **User cannot access a resource they should have access to**:
   - Check if the user has the necessary role (global or farm-specific)
   - Verify the role has the required permission
   - Ensure neither the role assignment nor permission assignment has expired
   - If checking farm-specific permissions, ensure you're passing the farm context
   - Refresh permissions to ensure they're up to date

2. **Permission not appearing in the admin interface**:
   - Run the permission discovery process
   - Check if the controller or action exists in the application
   - Verify the controller requires authentication

3. **Unexpected authorization errors**:
   - Check the Pundit policy for the resource
   - Verify the permission format matches what's in the database
   - Clear the permission cache if recent changes were made

### Debugging Tools

The `AuthorizationService` provides several helpful methods for debugging:

- `AuthorizationService.find_unauthenticated_controllers`: Lists controllers that don't require authentication
- `AuthorizationService.main_namespaces`: Shows all application namespaces
- `AuthorizationService.active_permissions`: Lists all active permissions
- `AuthorizationService.change_statistics`: Shows recent permission changes and statistics

## Conclusion

TuberHub's authorization system provides a flexible, dynamic approach to access control. By combining the power of Pundit with a database-driven permission system, it allows for fine-grained control over who can access what in the application, while remaining adaptable to changes in the application structure.

With the addition of farm-level authorization, TuberHub now supports complex multi-farm environments with different permission levels for each farm, providing a scalable solution for organizations managing multiple farms with different user access requirements.