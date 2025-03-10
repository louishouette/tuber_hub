Per-Parcel Computed Aggregates
------------------------------

### Production Statistics

*   **Total Production**: The total weight of all findings in the current season for a parcel (in grams)
    
*   **Per Location Production**: Average production per location with findings (g/location)
    
*   **Per Planting Production**: Average production across all plantings (g/planting)
    
*   **Per Producing Planting Production**: Average production for plantings that have produced findings (g/producing planting)
    

### Findings Distribution

*   **No Findings**: Count of locations with zero findings
    
*   **One Finding**: Count of locations with exactly one finding
    
*   **Two Findings**: Count of locations with exactly two findings
    
*   **Three Findings**: Count of locations with exactly three findings
    
*   **Four+ Findings**: Count of locations with four or more findings
    
*   **Replacements**: Count of locations that have had plants replaced
    

### Species Statistics

*   **Per Species Planting Count**: Number of plantings of each species in the parcel
    
*   **Per Species Findings Count**: Number of findings for each species
    
*   **Per Species Total Weight**: Total production weight for each species
    
*   **Per Species Average Weight**: Average weight per finding for each species
    
*   **Per Species Production per Planting**: Production ratio (g/planting) for each species
    
*   **Never Replaced Count**: Count of plantings that have never been replaced for each species
    

### Weekly Findings

*   **Findings by Week**: Count and total weight of findings aggregated by week
    

Refreshment Strategy and Frequency
----------------------------------

### Real-time Counters (Updated Instantly)

*   Basic counters (locations\_count, plantings\_count, findings\_count) using counter\_cache columns in the database
    

### Background Job Updates (Triggered on Changes)

*   When a finding is created/updated/deleted
    
*   When a planting is created/updated/deleted
    
*   When parcel planted\_at date changes
    
*   After database migrations
    

### Cached with Expiration (10 minutes to 1 hour)

*   Production statistics: cached for 1 hour
    
*   Findings distribution: cached for 1 hour
    
*   Species statistics: cached for 1 hour
    
*   Aggregated statistics: cached for 10 minutes
    

### Weekly Data (Refreshed Every 2 Days)

*   Weekly findings data stored in parcel.weekly\_findings\_data JSON column
    
*   Updated by background job if data is older than 2 days