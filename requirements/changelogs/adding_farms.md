# TuberHub Farm Management Changelog

## Background

Farm management is a core feature of TuberHub. This functionality allows users to create, read, update, and delete farms. Users can belong to multiple farms and select their current farm context. This changelog will track progress, issues, and decisions made during development.

### Development Workflow

1. **Maintain this Changelog**: Document all changes, decisions, and issues in this file
2. **Reference Documentation**: Always refer to relevant documentation for architectural guidance
3. **Incremental Development**: Make small, focused changes and test after each step
4. **Document Progress**: Add to this changelog after completing each task
5. **Review Documentation**: Ensure that the documentation is up-to-date and accurate

## [2025-03-19] Initial Farm Management Implementation

### Changes Made
- Created the Core namespace with Farm model, controller, and views
- Implemented farm-user associations allowing users to belong to multiple farms
- Added farm selection functionality in the navbar using the farm switcher component
- Implemented session-based tracking of the user's currently selected farm
- Created CurrentFarm concern for farm context management across requests
- Implemented Pundit policies for farm authorization
- Created JavaScript controllers for farm switcher with separation of business and UI logic
- Updated navbar to display the current farm's name and logo
- Created all necessary database migrations
- Added farms seed file to create sample farms during setup

### Issues Encountered
- Fixed multiple icon naming issues:
  - Replaced non-existent 'edit' icon with 'pencil' icon in farm index and show views
  - Replaced non-existent 'home' icon with 'house' icon in farm edit view
  - Replaced non-existent 'check-circle' icon with 'circle-check' in farm show view
  - Replaced non-existent 'x-circle' icon with 'circle-x' in farm show view
  - Removed unnecessary library and variant parameters from icon calls

## [2025-03-20] Farm Index and Show View Enhancements

### Changes Made
- Implemented card list layout for farm index view with improved visuals
- Added tabbed card layout for farm show view with three tabs: Details, Members, and Settings
- Enhanced farm detail display with better visual organization
- Improved member management UI with better error handling and user feedback
- Added farm settings section with controls for activation/deactivation and farm management
- Fixed bug with logo.attached? check by ensuring logo exists before calling attached?
- Improved farm show view with a responsive layout for both mobile and desktop
- Added fallback display when no farm members are present

### Technical Implementations
- Used Flowbite card and tabs components for consistent UI design
- Properly checked for existence of logo and avatar before accessing attached?
- Implemented responsive design principles for all screen sizes
- Improved error handling for missing or invalid data

## [2025-03-19] Remove Default Farm Functionality

### Changes Made
- Removed is_default column from hub_core_farm_users table
- Removed default farm management code from User model
- Updated farm switching mechanism to only track farm selection in the session
- Refactored FarmUser model to remove default farm callbacks and scopes
- Prepared for future implementation of a dedicated UserPreference model to handle default farm selection
- Fixed nil reference issues in the farm switcher component
- Removed references to the is_default column in the farm switcher view

### Issues Encountered
- Encountered NoMethodError (undefined method `attached?` for nil) in the farm_switcher partial
- Fixed RailsIcons::IconNotFound errors by using available icon names based on the app's icon documentation (replaced 'home' with 'house')
- Fixed layout issues in farm views by implementing a proper controller inheritance hierarchy

## [2025-03-20] Farm Membership Management

### Changes Made
- Created FarmUsersController to handle adding and removing members from farms
- Implemented full CRUD operations for farm memberships
- Added proper Pundit policies for controlling who can add/remove farm members
- Connected the farm show page members tab to the membership controller
- Implemented form for adding users to farms by email address
- Added dropdown actions for managing farm members
- Updated routes to support farm member management
- Ensured proper authorization at both farm and user level

### Issues Encountered
- None

### Next Steps
- Add error handling for edge cases in membership management

### Recent Fixes
- Fixed console errors related to missing event_emitter utility by integrating event handling directly into farm_switcher_controller
- Fixed server error in farm switching by resolving authorization conflict between NamespacePolicy and FarmPolicy
- Ensured proper farm authorization is applied when switching between farms

## [2025-03-20] Migration of Farms from Core to Admin Namespace

### Changes Made
- Moved Farm and FarmUser models from the core namespace to the admin namespace
- Updated all associations and validations in the migrated models
- Created new FarmsController and FarmUsersController in the admin namespace
- Implemented Pundit policies for Farm and FarmUser in the admin namespace
- Updated User model to reference the new Farm and FarmUser classes
- Migrated all farm-related views to the admin namespace
- Updated all path helpers and routes in views to use admin namespace
- Updated the CurrentFarm concern to reference the admin namespace for farms

### Technical Implementation
- Created new files instead of renaming to ensure compatibility with existing code
- Updated all form submissions and redirects to use the admin namespace paths
- Maintained the same functionality while reorganizing the codebase structure
- Preserved all controller actions and view layouts during migration

### Next Steps
- Update tests to reflect the namespace changes

## [2025-03-20] Cleanup of Core Namespace Farm Components

### Changes Made
- Removed all redundant core namespace farm components after successful testing
- Deleted the following files from the core namespace:
  - FarmsController and FarmUsersController
  - FarmPolicy and FarmUserPolicy
  - All core namespace farm views
  - FarmsHelper
- Fixed remaining references to Hub::Core::Farm class in admin views
- Updated placeholder content in admin view templates
- Added the farm management routes to the admin namespace
- Migrated database tables from core to admin namespace
- Added farm management link to the admin section of the sidebar
- Simplified the farm switcher UI by removing unnecessary links and improving the current farm indicator
- Enhanced the farm index page UI with cleaner cards showing farm descriptions and addresses

### Technical Implementation
- Performed a clean removal of all deprecated files
- Ensured no lingering references to the core namespace in the codebase
- Created a migration to rename the database tables and update foreign key relationships
- Added set_current_farm route to the admin namespace for farm switching functionality
- Completed the full migration from core to admin namespace

