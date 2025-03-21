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

- `Hub::Admin::User`: The user model that includes authentication and role-based capabilities.
- `Hub::Admin::Role`: Defines roles that can be assigned to users.
- `Hub::Admin::Permission`: Represents allowed actions on specific controllers.
- `Hub::Admin::RoleAssignment`: Links users to roles.
- `Hub::Admin::PermissionAssignment`: Links roles to permissions.
- `PunditHelper`: Extends Pundit with application-specific functionality.
- `PermissionService`: Manages permission discovery and access control throughout the application.

## Authorization Flow

1. When a request comes in, `ApplicationController` checks if the current user is authorized for the requested action.
2. The check is performed by Pundit policies, which consult the database-driven permission system.
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

1. The `PermissionService.discover_permissions` method scans all controllers in the application.
2. For each controller that requires authentication, it extracts:   
   - The namespace (e.g., `hub/admin`)
   - The controller name (e.g., `users`)
   - Available actions (e.g., `index`, `show`, `create`)
3. Permissions are created in the database with a standard format: `namespace/controller#action`.
4. Legacy permissions (those no longer existing in the application) are marked as such.

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

Authorization in controllers is handled through Pundit:  

```ruby
# Standard Pundit approach for model-based authorization
authorize @user

# For controller/namespace-based authorization
authorize_namespace('hub/admin', 'users', 'create')
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

## Cache Management

For performance reasons, permission checks are cached:  

- User permission results are cached for 1 hour
- Permission groups are cached for 15 minutes
- Available namespaces are cached for 1 hour

The cache is managed through specialized methods in the `PermissionService`:

- `clear_all_permission_caches`: Invalidates all permission-related caches
- `clear_user_permission_caches(user)`: Clears cache for a specific user
- `clear_permission_caches(namespace, controller, action)`: Clears cache for a specific permission

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

To improve performance, the system uses caching extensively:

```ruby
Rails.cache.fetch("user_#{user.id}_permission_#{namespace}:#{controller}:#{action}", expires_in: 1.hour) do
  # Permission check logic
end
```

To avoid N+1 queries when checking multiple permissions for a user, the system supports permission preloading:

```ruby
# Preload all permissions for a user
PermissionService.preload_user_permissions(user)

# Check permissions using preloaded data (faster)
PermissionService.user_has_permission?(user, namespace, controller, action, use_preloaded: true)
```

This approach significantly reduces database queries in pages that perform multiple permission checks.

## Troubleshooting

### Common Issues

1. **User cannot access a resource they should have access to**:
   - Check if the user has the necessary role
   - Verify the role has the required permission
   - Ensure neither the role assignment nor permission assignment has expired
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

The `PermissionService` provides several helpful methods for debugging:

- `PermissionService.find_unauthenticated_controllers`: Lists controllers that don't require authentication
- `PermissionService.main_namespaces`: Shows all application namespaces
- `PermissionService.active_permissions`: Lists all active permissions

## Conclusion

TuberHub's authorization system provides a flexible, dynamic approach to access control. By combining the power of Pundit with a database-driven permission system, it allows for fine-grained control over who can access what in the application, while remaining adaptable to changes in the application structure.