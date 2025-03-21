# TuberHub Authorization System Refactoring Changelog

## Background

The TuberHub authorization system currently implements a robust Role-Based Access Control (RBAC) system using Pundit. While functional, the system has accumulated technical debt and exhibits several issues that need addressing to improve maintainability, performance, and security. This changelog will track the refactoring effort to streamline and enhance the authorization system.

## Goals

1. Consolidate duplicate permission checking logic
2. Improve caching implementation for better performance and consistency
3. Optimize database queries to prevent N+1 problems
4. Enhance farm-level authorization
5. Simplify the overall class structure for better maintainability
6. Implement more efficient cache invalidation strategies
7. Add automatic permission discovery for new controllers
8. Ensure consistent admin user checks across the application

## Refactoring Program

### Phase 1: Analysis and Planning

1. **Document Current System**
   - Update the documentation of the current authorization flow in @docs/tuber_hub/AUTHORIZATION.md and @docs/tuber_hub/AUTHENTICATION.md
   - Refresh your Pundit knowledge by reading the Pundit documentation in @docs/pundit-2.4.0.md
   - Identify all places where permission checks occur
   - Map out the relationships between models and their role in the authorization process

### Phase 2: Core Permission Logic Refactoring

2. **Consolidate Permission Checking Logic**
   - Create a single source of truth for permission checks
   - Remove duplicate logic between `User#can?` and `PermissionIntegration#permission_check`
   - Create a unified interface for all authorization checks

3. **Standardize Caching Implementation**
   - Create a centralized caching approach for permissions
   - Define consistent cache key formats
   - Implement more efficient cache invalidation strategies

4. **Optimize Query Performance**
   - Refactor permission queries to use preloading where appropriate
   - Add indices for commonly queried permission combinations
   - Implement eager loading strategies for user permissions

### Phase 3: Structural Improvements

5. **Simplify Class Structure**
   - Reorganize authorization concerns and modules
   - Improve modularity and reduce coupling between components
   - Clarify responsibilities for each class in the authorization system

6. **Streamline Legacy Permission Handling**
   - Implement a more efficient approach to handling legacy permissions
   - Add option to archive and clean up unused permissions

### Phase 4: Feature Enhancements

7. **Implement Farm-Level Authorization**
   - Extend the permission system to include farm-specific permissions : a User role is scoped to a Farm
   - Add scoping based on farm membership
   - Support farm-specific roles

8. **Add Automatic Permission Discovery**
   - Implement hooks to automatically discover permissions when controllers are added/changed
   - Add Rails generators for authorization components

9. **Improve Error Handling and Messaging**
   - Enhance error messages for authorization failures
   - Add better logging for permission issues
   - Implement more user-friendly access denied messages

### Phase 5: Documentation and Cleanup

10. **Update Documentation**
    - Revise the authorization documentation to reflect the new approach
    - Add code examples for common authorization scenarios
    - Create diagrams showing the new authorization flow

11. **Performance Testing**
    - Benchmark the refactored authorization system
    - Identify and address any remaining performance bottlenecks

## Development Tracking

### [2025-03-21] Initial Planning

**Changes Made**
- Created comprehensive changelog for authorization refactoring
- Identified issues in the current implementation
- Planned phased approach to refactoring

**Next Steps**
- Begin Phase 1: Analysis and Documentation
- Create a detailed map of all permission check implementations
- Establish benchmarks for the current system performance

### [2025-03-25] Phase 2: Core Permission Logic Refactoring

**Changes Made**
- Created a centralized `PermissionService` as the single source of truth for permission checks
- Consolidated duplicate logic from `User#can?` and `PermissionIntegration#permission_check`
- Updated various components to use the centralized service:
  - Updated User model to use PermissionService
  - Refactored PermissionIntegration module
  - Updated NamespacePolicy
  - Enhanced PunditHelper methods
- Improved caching implementation with more granular cache invalidation methods:
  - Added `clear_all_permission_caches`
  - Added `clear_user_permission_caches(user)`
  - Added `clear_permission_caches(namespace, controller, action)`
- Optimized query performance:
  - Added support for preloading user permissions to prevent N+1 queries
  - Improved SQL queries with better WHERE clause organization
  - Added support for efficient querying of both unlimited and expiring permissions
- Updated documentation to reflect the new architecture

**Next Steps**
- Phase 3: Structural Improvements
- Implement farm-level authorization
- Add more comprehensive tests for the refactored components
