# TuberHub Authorization Policy Updates Changelog

## Background

The TuberHub authorization policies required updates for consistency and to align with current TuberHub patterns. This changelog tracks the updates made to fix deprecated or inconsistent policy implementations.

## [2025-03-21] Authorization Policy Standardization

### Changes Made

- Removed duplicate policy files (user_policy.rb and role_policy.rb) at the root level that were superseded by their namespaced versions in hub/admin/
- Updated ApplicationPolicy to use Current.user as fallback when user is nil
- Added missing permission_check method to NamespacePolicy
- Updated AdminPolicy with proper permission checking beyond just admin status
- Standardized Hub::Admin::FarmPolicy to use consistent permission checking
- Enhanced Hub::Admin::FarmUserPolicy with proper admin bypass and scope filtering
- Added PermissionPolicyConcern inclusion to policies that were missing it
- Ensured consistent pattern for permission checking across all policies

### Issues Encountered

- Duplicate policy files were causing confusion about which policy takes precedence
- Inconsistent permission checking methods across policies (some using user.can?, others using permission_check)
- Missing proper scope implementation in some policies
- Needed to ensure farm-scoped permissions were properly handled

### Next Steps

- Consider refactoring more complex permission checks into the PermissionPolicyConcern
- Add more robust test coverage for policy edge cases
- Consider documenting policy patterns in the authorization documentation
