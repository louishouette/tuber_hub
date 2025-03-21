# TuberHub Farm-Level Authorization Changelog

## Background

This feature extends TuberHub's existing authorization system to support farm-scoped permissions and roles. It allows administrators to assign farm-specific roles to users without affecting their global permissions. This is crucial for multi-farm environments where different users may have different levels of access to different farms.

## Development Workflow

1. **Maintain this Changelog**: Document all changes, decisions, and issues in this file
2. **Reference Documentation**: Always refer to relevant documentation for architectural guidance
3. **Incremental Development**: Make small, focused changes and test after each step
4. **Document Progress**: Add to this changelog after completing each task
5. **Review Documentation**: Ensure that the documentation in docs/tuber_hub/authorization.md is up-to-date and accurate.

## [2025-03-21] Initial Implementation of Farm-Level Authorization

### Changes Made

- Added farm_id to role_assignments table with database validation constraints
- Added farm association to RoleAssignment model with appropriate validations
- Updated PermissionService to support farm-scoped role resolution:
  - Modified user_has_permission? to accept a farm parameter
  - Updated role ID fetching to consider farm context
  - Added caching for farm-specific permissions
- Extended User model's can? method to support farm-level permissions
- Added has_farm_role? method to User model to check farm-specific roles
- Updated permission cache clearing to handle farm-specific permission caches
- Extended preload_user_permissions to work with farm-specific contexts
- Enhanced the PunditHelper module's controller/view helpers:
  - Updated allowed_to? helper to support farm-specific permissions
  - Modified authorize_namespace to accept farm parameter
  - Extended namespace_scope to work with farm context
- Updated PermissionIntegration module to extract farm context from records
- Modified NamespacePolicy to incorporate farm-level permission checks

### Implementation Details

#### Role Assignments

- Global roles (affecting all farms) have global=true and farm_id=nil
- Farm-specific roles have global=false and reference a specific farm_id
- Added validations to ensure roles are correctly assigned based on intended scope

#### Authorization Flow

1. When checking permissions, the system now takes into account the farm context
2. Permission Service queries both global roles and farm-specific roles when a farm is specified
3. For farm-specific contexts, both global permissions and farm-specific permissions apply
4. For global contexts, only global permissions are considered (farm-specific permissions are ignored)

### Completed Tasks

- Added farm-level authorization features to the permission service
- Updated and tested permission caching and preloading with farm context
- Validated role assignments with farm specificity 
- Enhanced models for checking farm-specific permissions
- Tested and verified all farm-level authorization functionality
- Updated documentation in docs/tuber_hub/AUTHORIZATION.md

### Next Steps (Future Improvements)

- Update controllers to pass farm context to permission checks where appropriate
- Add UI elements for managing farm-specific role assignments
- Implement farm selector in the UI for cross-farm administrators
