# TuberHub UI Reorganization Changelog

## Instructions for UI Development

### Background

The Hub namespace UI reorganization aims to create a cohesive, role-based navigation system that maintains farm context awareness across the application. This will improve user experience by providing clear access to different functional areas based on user roles while maintaining the current farm context throughout all views. The reorganization will create dedicated namespaces for admin, core, cultivation, and measurement functionalities, each with their own set of modules.

The UI reorganization is fundamental to the scalability and usability of TuberHub, allowing for the seamless addition of new features while maintaining a clear and intuitive navigation system.

### Development Workflow

1. **Maintain this Changelog**: Document all changes, decisions, and issues in this file
2. **Reference Documentation**: Always refer to relevant documentation for architectural guidance
3. **Incremental Development**: Make small, focused changes and test after each step
4. **Document Progress**: Add to this changelog after completing each task
5. **Review Documentation**: Ensure that the documentation in docs/tuber_hub/UI_ARCHITECTURE.md is up-to-date and accurate. Create it if needed.

### Changelog Format

For each development session, please structure your entries as follows:

```markdown
## [YYYY-MM-DD] Session Title

### Changes Made
- Description of change 1
- Description of change 2

### Issues Encountered
- Issue 1 and resolution
- Issue 2 and resolution

### Next Steps
- Task 1 to be done next
- Task 2 to be done next
```

## [2025-03-21] UI Reorganization Planning

### Changes Made
- Created initial UI reorganization plan
- Defined namespace structure for the application
- Outlined implementation phases and technical considerations

## [2025-03-26] User Profile Page Improvements

### Changes Made
- Moved the Edit button to the User Information card header for better consistency with other cards
- Prevented Current User from seeing the Deactivate button for themselves (users can't deactivate their own account)
- Changed the Manage button to View All in the Roles card with proper icon styling
- Replaced the + icon with an eye icon in the roles section to better represent the view action
- Added a Show All button to the User Activity card header
- Removed the icon before the User Preferences title for cleaner presentation
- Fixed the tabs in the User Preferences section to properly show active state and enable switching between tabs
- Updated all buttons to follow the TuberHub Action Button Styling Standards
- Improved the Stimulus tabs controller to properly handle tab switching and active styling

### Proposed Architecture

#### 1. Global Layout Components

1. **Persistent Navbar**
   - Farm selector dropdown (already implemented)
   - Apps dropdown menu for namespace navigation
   - User profile and authentication controls
   - Global notifications

2. **Dynamic Sidebar**
   - Role-based menu items that change based on:
     - Current namespace
     - User permissions
     - Selected farm context

3. **Main Content Area**
   - Title container with consistent styling
   - Content cards/tables with standardized styling

#### 2. Namespace Structure

1. **Admin Namespace**
   - Users management
   - Farms management
   - Roles and permissions management
   - System settings

2. **Core Namespace**
   - Dashboard (farm-specific overview)
   - Seasons management
   - Productions management

3. **Cultivation Namespace**
   - Primary Operations:
     - Irrigation operations
     - Fertilization operations
     - Treatment operations
     - Planting operations
     - Finding/harvest operations
     - Tiling operations
     - Mowing operations
     - Pruning operations
   - Secondary Configuration (parameters to the primary operations):
     - Irrigation system configuration (sectors, admissions, etc.)
     - Fertilization configuration (formulas, tools)
     - Treatment configuration (families, tools, formulas)
     - Planting configuration (orchards, parcels, rows, etc.)
     - Harvest configuration (runs, dogs, sectors)
     - Tiling/Mowing/Pruning tools configuration

4. **Measure Namespace**
   - Observations tracking
   - Soil analysis
   - Meteorological data
   - Plant measurements
   - Multispectral analysis

### Implementation Plan

#### Phase 1: Navigation Framework

1. **Update Application Layout**
   - Refactor navbar to include namespace selection dropdown
   - Rename the app/views/layouts/hub/shared/menu directory to sidebar
   - Create dynamic sidebar component that loads menu based on current namespace

2. **Create Namespace Controllers and Views** ✅
   - Generate base controllers for each namespace ✅
   - Set up routing for namespaces ✅
   - Create shared layouts for each namespace ✅

3. **Implement Farm Context Awareness** ✅
   - Ensure farm selection is persistent across namespaces ✅
   - Add farm context indicators to all views : already done with the farm selector in the navbar ✅
   - Implement farm filtering for all data queries ✅

#### Phase 2: Admin & Core Namespaces

1. **Admin Namespace Implementation**
   - Build users CRUD interface
   - Build farms CRUD interface
   - Build roles and permissions management
   - Implement system settings

2. **Core Namespace Implementation**
   - Create farm-specific dashboard
   - Implement seasons management
   - Implement productions management

#### Phase 3: Cultivation Namespace

1. **Operations Modules**
   - Implement all primary cultivation operations (irrigation, fertilization, etc.)
   - Create consistent UI patterns for operation entry and tracking

2. **Configuration Modules**
   - Build configuration components for each operation type
   - Ensure proper relationships between configuration and operations

#### Phase 4: Measure Namespace

1. **Data Collection Interfaces**
   - Build observation tracking system
   - Implement soil analysis views
   - Create meteorological data entry and visualization

2. **Analysis Views**
   - Design data visualization components
   - Implement reporting interfaces

### Technical Considerations

1. **Component Standardization**
   - Use consistent button styling as defined in UI standards
   - Implement card and table layouts according to design patterns
   - Create reusable components for common UI elements

2. **Authentication & Authorization**
   - Use Current.user for user context (not current_user)
   - Implement namespace and controller-level authorization
   - Create role-based menu filtering

3. **Farm Context Management**
   - Store selected farm in session (not in Current)
   - Ensure all controllers filter data by current farm context
   - Add farm switching without losing current namespace

4. **Navigation State Management**
   - Highlight current namespace in dropdown
   - Track and display active section in sidebar

### Issues Encountered
- None yet as this is the initial planning phase

### Next Steps

1. Create the necessary controller structure for namespaces
2. Implement sample views for each namespace to validate the approach
3. Implement Farm Context Awareness (Phase 1.3)

## [2025-03-24] Phase 1.1 Implementation: Update Application Layout

### Changes Made
- Refactored navbar to include namespace selection dropdown
- Created UI_ARCHITECTURE.md documentation file to detail the new structure
- Renamed the menu directory concept to sidebar
- Implemented dynamic sidebar component that loads menu based on current namespace
- Created namespace-specific sidebar menus for Admin, Core, Cultivation, and Measure
- Added farm context awareness in the sidebar
- Updated all icon usage to follow TuberHub standards (removed variant parameters)

### Implementation Details

1. **Namespace Selection Dropdown**
   - Replaced generic apps dropdown with namespace-specific navigation
   - Added visual indicators for current namespace
   - Improved styling with descriptive text and larger icons

2. **Dynamic Sidebar**
   - Created base sidebar structure that detects current namespace
   - Implemented namespace-specific menu files:
     - `/layouts/hub/shared/sidebar/admin/_menu.html.erb`
     - `/layouts/hub/shared/sidebar/core/_menu.html.erb`
     - `/layouts/hub/shared/sidebar/cultivation/_menu.html.erb`
     - `/layouts/hub/shared/sidebar/measure/_menu.html.erb`
   - Added active state indicators for current controller/action

3. **Documentation**
   - Created comprehensive UI architecture documentation
   - Detailed namespace structure and technical implementation
   - Provided UI standards and development guidelines

### Issues Encountered
- Had to use rescue in sidebar rendering to handle potential missing menu files
- Routes for many sections don't exist yet, so links are placeholders with rescue fallbacks

### Next Steps
1. Create the necessary controller structure for namespaces
2. Set up routing for namespaces
3. Implement sample views for each namespace to validate the approach
4. Implement Farm Context Awareness (Phase 1.3)
