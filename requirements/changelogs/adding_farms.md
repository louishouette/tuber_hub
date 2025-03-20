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
- None so far

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

### Next Steps
- presentation map :
  - index : use a card list 
  - show : use @docs/flowbite/card_with_tabs.html
- Implement farm membership management
- Develop UserPreference model for user customizations including default farm
