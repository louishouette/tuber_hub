# Plantings, Locations, and Season Statistics

## Fundamental Relationships

In the Tuber Scout system, the core relationships are structured as follows:

1. **Parcels** contain multiple **Locations** (through rows)
2. Each **Location** has one or more **Plantings** over time
3. The **original planting** at a location is the first planting historically placed there
4. If a planting dies or needs to be replaced, a new planting record is created for that location

## Location-Planting Relationship

The Location model is designed to track the history of plantings at each specific position in a parcel:

- Each location has one or more plantings over time
- The `Location#actual_planting` method returns the most recent planting (the one most likely still alive)
- We need a `Location#actual_planting_at(date)` method that would return the planting that was alive at a specific date (e.g., the start of a season)

## Statistical Tracking Over Time

The key purpose of this structure is to track the evolution of plantings across seasons:

1. See what was originally planted at each location
2. Track replacements through the years (including species changes)
3. Calculate statistics based on the plantings that were actually present at the start of each season

## Implementation Needs

To properly implement this system, we need to:

1. Enhance the Location model with an `actual_planting_at(date)` method to find the planting that was active at a given date
2. Modify the statistics calculation to use this method when determining which plantings were present at the start of each season
3. Ensure the ParcelsController correctly identifies both original and actual plantings for each season

## Season-Based Statistics

For each season, we want to track:

1. The original plantings at each location (initial historical records)
2. The actual plantings at the start of the season (which may differ from original plantings due to replacements)
3. The findings associated with these plantings in that season
4. Replacements that occurred during or after that season

This approach allows farmers to trace the complete history of their orchard, including species changes, mortality rates, and productivity trends over time.

## Statistical Importance

These distinctions are crucial for accurate yield analysis:

- Comparing original species with current species shows adaptation strategies
- Tracking which locations have had replacements helps identify problem areas in the parcel
- Seeing which trees were actually present at the start of each season provides accurate productivity metrics
