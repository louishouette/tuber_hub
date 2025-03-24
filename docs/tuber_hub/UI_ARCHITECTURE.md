# TuberHub UI Architecture

## Overview

TuberHub's UI architecture is designed to provide a cohesive, role-based navigation system that maintains farm context awareness across the application. The architecture is organized into distinct namespaces, each with its own set of modules and functionality.

## Key Components

### 1. Global Layout Components

#### Persistent Navbar
- **Farm selector dropdown**: Allows users to select and switch between farms
- **Namespace selector dropdown**: Provides access to different application areas (Admin, Core, Cultivation, Measure)
- **User profile and authentication controls**: Manages user session and profile access
- **Global notifications**: Displays system-wide notifications

#### Dynamic Sidebar
- Loads menu items based on the current namespace
- Adapts to user permissions
- Maintains farm context awareness
- Highlights active menu items

#### Main Content Area
- Standardized title containers
- Consistent card and table layouts
- Farm context indicators

### 2. Namespace Structure

#### Admin Namespace
- **Purpose**: System administration and user management
- **Key Features**:
  - Users management
  - Farms management
  - Roles and permissions management
  - System settings
  - Audit logs

#### Core Namespace
- **Purpose**: Farm overview and season management
- **Key Features**:
  - Dashboard (farm-specific overview)
  - Seasons management
  - Productions management
  - Reports

#### Cultivation Namespace
- **Purpose**: Agricultural operations and configuration
- **Key Features**:
  - Primary Operations:
    - Irrigation operations
    - Fertilization operations
    - Treatment operations
    - Planting operations
    - Finding/harvest operations
    - Tiling operations
    - Mowing operations
    - Pruning operations
  - Secondary Configuration:
    - Irrigation system configuration
    - Fertilization configuration
    - Treatment configuration
    - Planting configuration
    - Harvest configuration
    - Tools configuration

#### Measure Namespace
- **Purpose**: Data collection and analysis
- **Key Features**:
  - Observations tracking
  - Soil analysis
  - Meteorological data
  - Plant measurements
  - Multispectral analysis
  - Reports & visualizations

## Technical Implementation

### Navigation System

1. **Namespace Selection**
   - Located in the navbar
   - Dropdown interface for switching between namespaces
   - Visually indicates current namespace

2. **Dynamic Sidebar**
   - Located in `app/views/layouts/hub/shared/sidebar/`
   - Namespace-specific menus in subdirectories
   - Dynamic loading based on controller path

### Farm Context Management

1. **Farm Selection**
   - Stored in session (not in Current)
   - Accessible via `current_farm` helper
   - Displayed in sidebar for context awareness

2. **Data Filtering**
   - All controllers filter data by current farm context
   - Farm context is maintained when switching namespaces

### Authentication & Authorization

1. **User Context**
   - Uses `Current.user` for user context
   - Role-based menu filtering
   - Namespace and controller-level authorization

## UI Standards

### Component Styling

1. **Buttons**
   - Primary action: Blue with icon
   - View action: Blue text
   - Edit action: Gray text
   - Delete action: Red text

2. **Cards & Tables**
   - Consistent border, padding, and rounded corners
   - Standardized header styling
   - Consistent action button placement

### Icons & Visual Elements

1. **Iconography**
   - Consistent use of Heroicon set (outline variant)
   - Namespace-specific icons for recognition
   - Function-specific icons for common actions

2. **Color System**
   - Primary: Blue for active items and primary actions
   - Gray scale for most UI elements
   - Red for destructive actions
   - Proper dark mode support

## Development Guidelines

1. **Maintain Namespace Separation**
   - Keep controllers and views organized by namespace
   - Use namespace-prefixed routes
   - Follow naming conventions for consistency

2. **Preserve Farm Context**
   - Always consider the selected farm in queries
   - Provide clear farm context indicators
   - Allow seamless farm switching

3. **Follow UI Standards**
   - Use established component patterns
   - Maintain consistent layout structures
   - Follow accessibility best practices

4. **Document Changes**
   - Update this document when architecture changes
   - Document namespace-specific conventions
   - Note any deviations from standards
