# TuberHub Authorization System

## Overview

TuberHub employs a role-based access control (RBAC) system built on the Pundit gem. The system provides:

1. **Pundit Policies**: Object-level authorization
2. **Roles & Permissions**: Feature-level access control
3. **Farm-scoped Access**: Multi-tenant data isolation
4. **Automatic Permission Discovery**: Tracking and managing permissions
5. **Authorization Auditing**: Security monitoring and debugging

## Core Components

### Users, Roles, and Permissions Model

- **User**: Entity requiring access to resources
- **Role**: Collection of permissions (e.g., Admin, Manager, Viewer)
- **Permission**: Specific controller action access (e.g., `hub/admin/users#create`)
- **Role Assignment**: Links users to roles (with optional farm-context and expiration)
- **Permission Assignment**: Links roles to permissions

### Key Models

- `Hub::Admin::User`: User model with authentication and role capabilities
- `Hub::Admin::Role`: Roles that can be assigned to users
- `Hub::Admin::Permission`: Allowed actions on controllers
- `Hub::Admin::RoleAssignment`: Links users to roles with optional farm context
- `Hub::Admin::PermissionAssignment`: Links roles to permissions
- `Hub::Admin::AuthorizationAudit`: Logs authorization failures

### Authorization Services

- `AuthorizationService`: Facade providing unified interface to all authorization functionality
- `Authorization::QueryService`: Handles permission checks
- `Authorization::ManagementService`: Manages permission discovery
- `Authorization::CacheService`: Handles permission caching
- `Authorization::AuditService`: Tracks authorization activities

## Authorization Flow

1. Request enters `ApplicationController` which checks current user authorization
2. Authorization check follows this pattern:
   - Controller calls Pundit's `authorize` or `AuthorizationConcern` helpers
   - Pundit policies use `PermissionPolicyConcern` → `AuthorizationService` → `Authorization::QueryService`
   - Permissions are checked against database with caching for performance
3. Certain controllers bypass authorization (public pages, authentication controllers)
4. Admin users automatically have full access

## Integration with Rails 8 Authentication

- Uses `Current.user` for permission checks
- Authentication runs before authorization checks
- Authentication controllers bypass authorization checks
- Pundit configured with `Current.user` instead of `current_user`

## Permission Management

### Discovery & Refresh

- System automatically discovers permissions from controller actions
- Extracts namespace, controller, action information
- Creates/archives permissions in database with descriptions
- Refresh via service: `AuthorizationService.refresh_permissions`
- Refresh via rake: `rails authorization:refresh_simple`

### Assignment

Administrators can assign permissions to roles and roles to users through the admin interface, with optional expiration dates for temporary access.

## Using Authorization

### Controllers

```ruby
# Object-based authorization
authorize @user

# Permission checks
user_can?(:create, 'users', 'hub/admin')
authorize_action!(:create, 'users', 'hub/admin')  # raises exception

# Farm-specific permissions
user_can?(:create, 'users', 'hub/admin', farm: @farm)

# Feature flags
feature_enabled_for_user?(:some_feature)
```

### Views and Helpers

```ruby
# Check permissions
allowed_to?(:update, @post)
allowed_to?(:create, { namespace: 'hub/admin', controller: 'users' })

# Scope collections
@users = policy_scope(User)
@users = namespace_scope(User, namespace: 'hub/admin', controller: 'users')
```

## Special Cases

### Public Controllers

These bypass authorization checks:
- Home/static pages
- Controllers in 'public' namespace
- Controllers that skip authentication

### Admin Users

Users with 'admin' role have universal access to all resources.

### Farm-Level Authorization

- **Global Roles**: Apply across entire application
- **Farm-Specific Roles**: Apply only to specific farms

```ruby
# Farm-specific permission checks
Current.user.can?(:manage, 'hub/admin', 'tubers', farm: @farm)
allowed_to?(:manage, { namespace: 'hub/admin', controller: 'tubers', farm: @farm })
authorize_namespace(farm: @farm)
@crops = namespace_scope(Crop, farm: @farm)

# Check specific farm role
user.has_farm_role?("Farm Manager", @farm)
```

#### Permission Resolution Logic

- In farm context: User must have either global permission OR farm-specific permission
- In global context: Only global roles are considered

## Caching System

- User permissions cached for 1 hour
- Farm-specific permissions cached separately
- Permission groups cached for 15 minutes
- Namespaces cached for 1 hour

```ruby
# Cache management methods
AuthorizationService.clear_all_permission_caches
AuthorizationService.clear_user_permission_caches(user, farm: nil)
AuthorizationService.clear_permission_caches('hub/admin', 'users', 'create')
```

## Best Practices

1. Use provided helpers instead of custom authorization logic
2. Refresh permissions after controller changes
3. Use time-limited roles for temporary access
4. Check authorization in every controller action
5. Use policies for object-level authorization
6. Prefer role-based permissions over individual assignments
7. Review authorization audits regularly

## Technical Details

### Permission Format

Standard format: `namespace/controller#action`
Examples: `hub/admin/users#create`, `hub/core/farms#update`

### Performance Optimization

```ruby
# Preload permissions to avoid N+1 queries
AuthorizationService.preload_user_permissions(user)
AuthorizationService.preload_user_permissions(user, farm: @farm)

# Use preloaded data in checks
AuthorizationService.user_has_permission?(user, namespace, controller, action, use_preloaded: true)
```

## Troubleshooting

### Common Issues

1. **Access issues**:
   - Verify user has required role (global or farm-specific)
   - Check if role has required permission
   - Ensure no expired role/permission assignments
   - For farm permissions, confirm farm context is passed
   - Check authorization audit logs

2. **Missing permissions**:
   - Run `rails authorization:refresh_simple`
   - Verify controller/action exists and requires authentication

3. **Unexpected errors**:
   - Check Pundit policy implementation
   - Verify permission format in database
   - Clear cache with `AuthorizationService.clear_all_permission_caches`

## Development Tools

### Generators

```bash
# Generate policy with RBAC integration
rails generate hub:authorization:policy Model [--namespace=Namespace]

# Generate controller with authorization
rails generate hub:authorization:controller Namespace ControllerName [--actions=index,show,create,update,destroy] [--farm-scoped]
```

### Rake Tasks

```bash
# Refresh permissions
rails authorization:refresh_simple

# Generate permission report
rails authorization:report_simple
```

## Summary

TuberHub's authorization system combines Pundit with a database-driven permission system for fine-grained access control. With farm-level authorization support, it enables different permission levels across multiple farms within a single application.