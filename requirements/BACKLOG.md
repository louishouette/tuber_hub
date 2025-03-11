FEAT: modularizing_the_app

We want to modularize our app by splitting it into the following namespaces :
  - cultivation namespace : 
    - irrigation model : started_at, duration_in_min, sector, operator, ended_at, volume_per_tree_in_l
    - fertilization model : application_at (day), tool, formula, rows, dosage, comment, operator
    - treatment model : application_at (day), tool, formula, rows, comment, operator
    - planting model : planted_at (day), species, comment, planter, nursery, inoculation, has_and_belongs_to_many :locations
    - finding model : run, sector, dog, harvester, started_at, stopped_at, found_at, comment, raw_weight, net_weight, surveyor
    - tiling model : tiling_at (day), tooling, row, comment, operator
    - mowing model : mowing_at (day), tooling, row, comment, operator
    - prunning model : prunning_at (day), architecture, row, comment, pruner
    - irrigation namespace : 
      - sector model : name, rows, admission, tertiary, description
      - admission model : tap type, diameter, pressure
      - tertiary model : diameter, flow, pressure, spacing, dispenser, has_flush_valve, secondary
      - primary model : diameter, flow, pressure
      - secondary model : diameter, flow, pressure, primary
      - dispensers model : brand, name, radius, is_regulated
    - fertilization namespace : 
      - formula model : nursery, name, description, density, weight_in_g
      - tool model : name, description
    - treatment namespace : 
      - family model : name, description
      - tool model : name, description
      - formula model : family, molecule, comment
    - planting namespace : 
      - orchard model : name, gis, description, farm
      - parcel model : name, gis, description, orchard
      - row model : name, gis, description, parcel
      - location model : name, gis, description, row, has_and_belongs_to_many :plantings
      - species model : name, description
      - nursery model : name, description
      - inoculation model : name, description
    - harvesting namespace : 
      - run model : sector, dog, harvester, started_at, stopped_at, comment, raw_weight, net_weight, surveyor
      - dog model : name, born_at, description
      - sector model : name, rows, description
    - tiling namespace : 
      - tool model : name, description
    - mowing namespace : 
      - tool model : name, description
    - pruning namespace : 
      - architecture model : name, description
      - pruner model : adds specific pruners from outside services companies to the farm's users with pruning rights
  - observation namespace : 
    - type model : name (faunistic, floristic, infrastuctural, phenological, abiotictical, biotictical), description
    - record model : observation, type, location, date, comment, observer
  - measures namespace : 
    - soil_analysis model : name, description
    - soil_resistivity model : name, description
    - soil_moisture model : name, description
    - meteorological model : name, description
    - plant_electrophysiology model : name, description
    - multispectral model : name, description
  - market namespace : 
    - channel model : name, description
    - segment model : name, description
    - place model : name, region, country, description
    - price_record model : place, quality, value, quantity, date, source
  - operation namespace : 
    - season model : name, description
    - intake model : name, description
  - admin namespace : 
    - user model : name, email, password, role
    - farm model : name, description

Considering your global understanding of the app, make a critic of this design. Answer with text, and/or structure, not code

FEAT: improving_topology_parcel
Index page :
- update the ratios to use the proper formulas, like done in the show view
Show view :
- The Statistic by Planting Age section comes at the end in a table, with per planting age :
  - per available species for this age :
    - Number of plantings
    - Number of findings
    - Number of replacements
    - Production (g)
    - Yield (g/plant)
    - Average weight (g/truffe)

FEAT: refine_locations_in_analysis
- add the POSTGIS point to the Location model and imports

FEAT: CRUD_to_add_or_improve
- add photo, age and all missing data to the dogs
- inoculations
- customers
- replacements
- topology
- species
- harvesting sectors
- OMS

FIX:
- localize the app
- apply the general layout design
- add a footer
- use preferences for dogs when creating a new run
- refactor caching for the dogs index
- rename the timestamps to be proper to their function (create a findings found_at instead of using the created_at)
- check if we can safely remove the "weekly_findings_data" attribute from the Parcel model

FEAT: open_access_to_everyone
- add a can_login attribute to the User model or a custom method to deactivate users
- use preferences for language
- localize the app
- use pundit for authorization : https://github.com/varvet/pundit
- when the user isn't logged in, he should not see the horizontal navbar
- after the first loggin, he still shouldn't see anything before he's changed his password
- the admin should be able to see a link to the users
- fix the forgot password process
- the first login shows a change password page in a loop

FEAT: rework_the_market_places_views
- index view
  - group the cards by statuses :
    - active requiring an update (published a record in the current season, but no update for a week) 
    - active up to date (published a record in the current season, the last one was less than a week ago)
    - inactive otherwise
  - add the status filter to the index search bar
  - show the status in the cards (a little green dot like it is done for an Associated Markets in a segment show view)
  - add price and volume informations :
    - active requiring an update markets :
      - "Sentence introducing the data and saying how fresh it is"
      - last average week price
      - last average week volume
    - active up to date markets :
      - "Sentence introducing the data and saying how fresh it is"
      - last average week price vs current week average price and an arrow to tell the tendancy (up, down or flat)
      - last average week volume vs current week average volume and an arrow to tell the tendancy (up, down or flat)
    - inactive markets :
      - "Sentence introducing the data and saying it is not fresh, and it is an average of the last 20xx-20yy season"
      - that season's average price
      - that season's cumulated volume
- show view
  - rework the chart "Market Activity This Season" using inspiration from "Market Activity" in a segment show view
  - avg price for a market and a broker?
  - add minimum_calculated_price, average_calculated_price and maximum_calculated_price, agregated_quantities attributes to the MarketPriceRecord model, and calculate these fields on value change :
    - minimum_calculated_price = minimum of values not null nor zero of (avg_price_per_kg, c1_price_per_kg, c2_price_per_kg, c3_price_per_kg, extra_price_per_kg, max_price_per_kg, min_price_per_kg )
    - average_calculated_price = average of values not null nor zero of (avg_price_per_kg, c1_price_per_kg, c2_price_per_kg, c3_price_per_kg, extra_price_per_kg, max_price_per_kg, min_price_per_kg )
    - maximum_calculated_price = maximum of values not null nor zero of (avg_price_per_kg, c1_price_per_kg, c2_price_per_kg, c3_price_per_kg, extra_price_per_kg, max_price_per_kg, min_price_per_kg )
    - agregated_quantities = si quantities_sold_per_kg then quantities_sold_per_kg else quantities_presented_per_kg else 0
  - Columns to show on the table : DATE, minimum_calculated_price, average_calculated_price, maximum_calculated_price, agregated_quantities keeping the actual names. 
  - make sure the calculated and agtregated fields are the ones used everywhere else in the app
  - Present the sum or avg values of the data at the end of the "Market Prices" table (prices are averaged, volumes are summed)

FEAT: rework_the_market_segments_views
- Market Segments
  - index view
    - check if ok
    - some refining required here

IDEA: rework_the_harvester_users
- Harvesters
  - One card per harvester with :
    - name
    - photo
    - comment
    - cumulated Harvesting Run time and cumulated Findings
    - average harvesting run duration
    - Table with stats per dog for the 5 best dogs
      - Dog : findings (gives the sorting order) : average time before the first finding : average time to make a finding
    - Table with stats per parcel for the 5 best parcels
      - Parcel : findings (gives the sorting order) : average time before the first finding : average time to make a finding

FEAT: rework_harvesting_flow
- refine the harvesting runs flow for the Harvesters
- add the choice between either the search field or scanning the qr_code when filling the label field for a new finding

FEAT: implement_a_proper_notifications_system
- implement a proper notifications system for persistent notifications

CHORE:
- change the atribute "duration" of the HarvestingRun model for "duration_in_min"
- replace the svg calls with flowbite icons
- add https://github.com/rameerez/allgood
- improve latency of statistics with https://github.com/tycooon/memery
- "If any of the locations don't have location_plantings, this could cause a nil error." We need a script that checks the location_plantings, planting and location tables for orphan records

IDEAS:
- add celebrations with https://github.com/avo-hq/stimulus-confetti
- add the ability to generate GIS reporting maps
- a weekly cumulated tab where we can select the week to display (by week number formatted as week 48 - 2024, week 49 - 2024, week 50 - 2024)
- a yearly cumulated tab where we can select the season to display (2022-2023, 2023-2024, 2024-2025)
- create a collection model to tag locations to group logical location.planting with a collection.name, a collection.description and a collection.category (like planting_wave, test, whatever) or create a planting_wave model, a test model etc...? That would reflect how we grouped by species, nursery etc...
- Use this gem for faster stats : https://github.com/ankane/active_median
- Use this gem for showing quick maps : https://chartkick.com/mapkick
- Weather correlation with the number of findings
- Tie a user to a domain

PROMPT:

CONSOLE:

FEAT: improve_harvesting_runs_for_surveyors
- Impossible to search for a finding from the location model if the location has the letters FBH or QG in it
  - check the harvesting runs' harvesting sector and identify the domain and the orchard
  - launch the search only on the domain's orchard's locations
  - add a filter on the query to search only for the location's name on the parts that come after the first [DOMAIN]-[ORCHARD]-
  - or compile a searchfield that excludes the domain and orchard names and search against it
- Prefill the Stopped at attribute when editing a run with the same value as started_at + 1hour

FEAT: KPI_for_CFO
- Temps moyen pour écouler la production
- Perte moyenne en % par jour de stockage