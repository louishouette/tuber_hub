# TuberHub Development Changelog: User Preferences

## Instructions for Feature Development

### Background

The User Preferences feature will allow users to customize their experience within the TuberHub application by storing and retrieving personal preferences. This includes setting a default farm for easy access, display preferences, and other customizable settings. This feature enhances user experience by maintaining consistent settings across sessions and providing personalized interactions.

The User Preferences system will be implemented as a flexible key-value store that can accommodate various types of preferences without requiring schema changes for new preference types.

### Development Workflow

1. **Maintain this Changelog**: Document all changes, decisions, and issues in this file
2. **Reference Documentation**: Always refer to relevant documentation for architectural guidance
3. **Incremental Development**: Make small, focused changes and test after each step
4. **Document Progress**: Add to this changelog after completing each task
5. **Review Documentation**: Ensure that the documentation in docs/tuber_hub/user_preferences.md is up-to-date and accurate. Create it if needed.

## [2025-03-25] Initial Implementation Plan

### Development Plan

#### 1. Database Schema and Model Creation
- Create a migration for the `user_preferences` table
  - References `hub_admin_users` table to align with existing namespace structure
  - `key` column (string) for preference identifier
  - `value` column (text) for storing serialized preference data
  - Add database indexes on `user_id` and `key` columns for performance
  - Add timestamps

#### 2. Model Implementation
- Create `Hub::Admin::UserPreference` model with:
  - `belongs_to` association to `Hub::Admin::User`
  - Validations for required attributes
  - `update_value` method with logging support
  - Appropriate scopes for efficient querying

#### 3. User Model Extensions
- Add `has_many :user_preferences, dependent: :destroy` association to `Hub::Admin::User`
- Implement helper methods for preference management:
  - Method to retrieve preference with default fallback
  - Method to set preferences
  - Method to handle default farm selection through preference system

#### 4. Controller Integration
- Integrate with session management for farm selection
- Update relevant controllers' strong parameters to handle user preferences
- Follow TuberHub's controller hierarchy and authorization pattern
- Create appropriate policy for UserPreferences
- Leverage `Current.user` for accessing the current user (not `current_user`)

#### 5. Authorization and Policy Configuration
- Create policy for UserPreference model following TuberHub's policy structure
- Add appropriate permissions for user preference management
- Ensure policy respects farm-scoped permissions when needed

#### 6. Default Farm Implementation
- Modify existing farm selection mechanism to use user preferences
- Respect the Current object pattern for farm context
- Enhance session handling through UserPreference model
- Preserve existing farm context pattern in views

## [2025-03-25] Implementation Progress

### Completed Tasks

#### 1. Model Enhancements
- Enhanced `Hub::Admin::UserPreference` model with:
  - Type validation for common preference types (integers, booleans, strings, hashes)
  - Added `description` method to provide human-readable descriptions of preferences
  - Added scopes for filtering system vs. user-defined preferences
  - Added JSON serialization for preference values
  - Implemented validation for typed preferences

#### 2. User Model Extensions
- Extended `Hub::Admin::User` model with comprehensive preference management:
  - Added `delete_preference` method to remove preferences
  - Added `has_preference?` method to check if a preference exists
  - Added methods to access user-defined and system preferences separately
  - Added `clear_default_farm` method to remove default farm setting
  - Added convenience methods for common preferences (`items_per_page`, `notifications_enabled?`)

#### 3. Controller and Views
- Enhanced `UserPreferencesController` with:
  - Added `settings` action for a centralized settings page
  - Added `update_preference` action for updating preferences via AJAX or form submission
  - Improved `set_default_farm` to handle clearing the default farm
  - Updated pagination to use the user's preference for items per page

#### 4. User Interface
- Created a comprehensive settings page at `/hub/admin/user_preferences/settings`
  - Organized settings into categories (Farm, Interface, Notifications)
  - Implemented forms for updating each preference type
  - Added navigation between preference categories
  - Used consistent styling following TuberHub design patterns

#### 5. Navigation Integration
- Added settings link in the user profile dropdown menu
  - Used appropriate icon and styling
  - Made settings easily accessible from anywhere in the application

This changelog will be updated as development progresses to track changes, decisions, and any issues encountered.

## [2025-03-25] UI Improvements - User Profile and Settings

### Planned Changes

#### 1. Navigation and Menu Updates
- Update navbar profile dropdown:
  - Replace the Settings link with user's current role
  - Keep My Profile link properly linked to current user view
- Remove Settings link from admin sidebar menu (between Farm and Audit)
- Replace the 3 utility links at the bottom of sidebar (_sidebar.html.erb) with application version (TuberHub.version)
- Delete language partial completely (no longer needed)

#### 2. Profile and Preferences Integration
- Merge the settings page into the current user show view:
  - Integrate all setting categories into a tabbed interface on the user profile page
  - Maintain consistent styling with existing UI patterns
- Add new preference options:
  - Language preference (showing available translations - currently just English but prepared for French)
  - Timezone preference (allowing users to set their preferred timezone)

#### 3. Documentation Updates
- Update USER_PREFERENCES.md with details about the new UI layout and available settings
- Document how to access and manage user preferences through the integrated profile view
