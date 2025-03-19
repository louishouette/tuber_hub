# Planting History Tracking

This document explains the planting history tracking system in Tuber Scout, focusing on distinguishing between original plantings and actual plantings at different points in time.

## Key Concepts

### Original vs. Actual Plantings

- **Original Planting**: The first (earliest) planting at a specific location. This is determined by the `planted_at` date.
- **Actual Planting**: The planting that is currently alive at a location (the most recent planting). This is determined by the most recent `planted_at` date.

### Original Plantings for a Season

A planting is considered an "original planting" for a specific season if:
1. It was planted BEFORE the start of that season
2. But NOT before the start of the previous season

This concept is different from "original planting at a location" and ensures each planting is counted as an original planting for exactly one season - the first season it could potentially produce truffles.

### Active Planting at a Point in Time

The active planting at a specific date is the planting that was alive at that date (the most recent planting as of that date).

## Available Methods

### Location Model Methods

- `Location#actual_planting`: Gets the most recent planting at the location (currently alive)
- `Location#actual_planting_at(date)`: Gets the planting that was active at a specific date
- `Location#original_planting`: Gets the first (earliest) planting at the location

### Planting Model Methods

- `Planting#original_for_season?(season_start)`: Checks if a planting is an original planting for a specific season
- `Planting#original_at_location?`: Checks if a planting is the first planting at its location
- `Planting#active_at_season_start?(season_start)`: Checks if a planting was active at the start of a specific season

### Seasonable Concern Methods

- `is_original_planting_for_season?(inoculation_id, planting_date, target_season_start)`: Determines if a planting date belongs to the original plantings of a season
- `get_active_plantings_at_season_start(parcel_id, season_start)`: Gets all active plantings for a parcel at the start of a season
- `get_original_plantings_for_parcel(parcel_id)`: Gets the original (first) plantings for each location in a parcel
- `get_replacements_in_season(parcel_id, season_start, season_end)`: Gets replacements that occurred during a specific season
- `compare_season_plantings(parcel_id, season1_start, season2_start)`: Compares plantings across two seasons to identify changes

## Example Usage

```ruby
# Get the active planting at a specific date
location = Location.find(123)
active_planting = location.actual_planting_at(Date.new(2023, 6, 1))

# Check if a planting is the original planting at its location
planting = Planting.find(456)
is_original = planting.original_at_location?

# Get all active plantings at the start of a season
parcel = Parcel.find(789)
season_start = Date.new(2023, 11, 1)
active_plantings = Finding.get_active_plantings_at_season_start(parcel.id, season_start)

# Compare plantings across two seasons
season1_start = Date.new(2022, 11, 1)
season2_start = Date.new(2023, 11, 1)
comparison = Finding.compare_season_plantings(parcel.id, season1_start, season2_start)
```

## Demonstration Script

A demonstration script is available at `lib/tasks/demos/plantings_location_history.rb` that shows how these methods work with real data. Run it with:

```
rails runner lib/tasks/demos/plantings_location_history.rb
```

## Visual Explanation

```
Timeline for a single location:
|--------------------------------|--------------------------|---------------------------|
2019-03-12                      2020-05-12                 2024-03-01
Planting A (original)           Planting B (replacement)   Planting C (replacement)
Downy Oak                       Downy Oak                  Downy Oak
                                                           
Season 2021-2022: Active planting is B
Season 2022-2023: Active planting is B
Season 2023-2024: Active planting is B
Season 2024-2025: Active planting is C
Season 2025-2026: Active planting is C

Original planting for this location: A
```

## Using This Data

These methods are useful for:

1. Tracking replacement history (which plantings replaced others)
2. Analyzing survival rates of original plantings
3. Comparing plantings across seasons to identify trends
4. Calculating accurate statistics for specific seasons
