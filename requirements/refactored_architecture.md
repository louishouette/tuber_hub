# Refactored Architecture - Tuber Scout

This document describes the refactored architecture implemented for the parcels controllers and related components.

## Overview

The original monolithic parcels controller has been refactored into smaller, more maintainable components following the Single Responsibility Principle. The new architecture consists of:

1. Service Classes - Organized in modules
2. Query Objects
3. Presenters 
4. Concerns

## Service Classes

Services are organized in a namespace structure to better categorize related functionality:

### Excel Export Services

Located in: `/app/services/excel_export/`

- `BaseService`: Base class that provides common Excel formatting and generation methods
- `ParcelService`: Generates Excel reports for parcels data
- `WeeklySummaryService`: Generates weekly summary reports
- `WeeklyProductionService`: Generates detailed weekly production reports

All Excel export services follow best practices:
- Proper error handling with begin/rescue blocks
- Graceful handling of nil values and division by zero
- Consistent formatting of values (especially for derived metrics)
- Proper memory management

## Query Objects

Located in: `/app/queries/`

- `ParcelStatisticsQuery`: Encapsulates complex query logic for retrieving and filtering parcel statistics

Query objects handle:
- Complex query logic
- Applying filters
- Database efficiency (minimizing N+1 queries)
- Data aggregation

## Presenters

Located in: `/app/presenters/`

- `ParcelPresenter`: Formats data for a single parcel view
  - `display_name`: Formats parcel name
  - `display_plantation_date`: Formats plantation date
  - `display_age`: Shows spring age
  - `display_total_locations`: Provides location count
  - `display_replacement_count` and `display_replacement_percentage`: Handles replacement stats
  - `display_producers_count` and `display_producer_ratio`: Formats producer statistics
  - `display_total_weight`, `display_average_weight`: Formats weight data
  - `display_production_per_tree`, `display_production_per_producer`: Calculates and formats ratio metrics
  - `display_species_breakdown`, `display_rootstock_breakdown`: Provides formatted distribution data
  - `display_weekly_findings`, `format_week`: Handles time-series data

- `ParcelsIndexPresenter`: Handles data presentation for the index view with collection-level statistics
  - `total_parcels_count`, `total_locations_count`: Aggregation counters
  - `total_producers_count`, `overall_producer_ratio`: Aggregated producer metrics
  - `total_findings_count`, `total_weight`: Production metrics
  - `average_weight`, `production_per_tree`: Calculated ratios
  - `active_filters_description`: Formats active filters

Presenters are responsible for:
- Data formatting for views
- Calculation of derived metrics
- Consistent display formatting
- Nil-safe operations
- Localization and internationalization support

## Concerns

Located in: `/app/concerns/` and `/app/models/concerns/`

- `Filterable`: Extracts filter processing logic into a reusable module
- `WeekFormattable`: Provides consistent week string formatting
- `WeeklyStatistics`: Adds weekly data grouping capabilities to the Finding model

## Controller

With the refactored architecture, the controller is now simpler and focused on:
- HTTP request/response handling
- Routing
- Basic parameter handling
- Delegating to appropriate services, queries, and presenters

## Best Practices

Throughout the refactored code, we've implemented these best practices:

1. **Error Handling**: Begin/rescue blocks with proper error logging
2. **Nil Value Handling**: Safe navigation, nil coalescing, explicit type conversion
3. **Zero Division Protection**: Always check denominators before division
4. **Meaningful Data Representation**: Format zero values appropriately based on context
5. **Data Integrity**: Validate data before computation
6. **Code Organization**: Smaller, focused classes with clear responsibilities

## View Templates

The view templates have been updated to leverage the presenter methods for consistent data display:

### Parcels Index

- Added a summary statistics card at the top showing overall metrics
- Improved display of complex metrics using presenters
- Clear visualization of producer ratios and production figures
- Consistent formatting of metrics across all views

### Parcel Show Page

- Enhanced display of parcel details using presenter methods
- Added species breakdown visualization
- Improved weekly findings display with proper formatting
- All calculated metrics now use consistent formatting and error handling

## Export Features

The Excel export functionality has been updated to use the modular service architecture:

- All export services now live in the `ExcelExport` namespace
- Proper error handling with begin/rescue blocks
- Consistent file naming conventions
- Support for multiple report types (standard, weekly_summary, and full_production)

## Future Improvements

Potential future improvements include:

1. Adding caching for expensive calculations
2. Further breaking down large service methods into smaller, more focused methods
3. Adding more presenter methods for specialized view requirements
4. Implementing interface documentation for service classes
5. Adding front-end visualizations (charts, graphs) for key metrics
