# FEAT: setup kamal
- security find-internet-password -a 'lmmh' -l 'Docker Credentials' -w for retrieving docker credentials

# FEAT: displaying different layouts
- the following pages will be accessible only after loging in :
  - /club
  - Tuber HUB : https://hub.truffiere-de-cement.fr
  - Marketplace : https://marketplace.truffiere-de-cement.fr

# FEAT: authorization
- refine the authorization process
- log user activity

# FEAT: permissions
Tuber HUB is the internal ERP tool to manage ressources and operations and to create reports.
For now it is quite empty, but we need to add the following namespaces, which will all reside under the hub namespace.

- core : the namespace to manage the main elements
  - farm : MVC
  - season : MVC
  - production : MVC
- cultivation : the namespace to manage the cultivation elements
  - irrigation MVC : started_at, duration_in_min, sector, operator, ended_at, volume_per_tree_in_l
  - fertilization MVC : application_at (day), tool, formula, rows, dosage, comment, operator
  - treatment MVC : application_at (day), tool, formula, rows, comment, operator
  - planting MVC : planted_at (day), species, comment, planter, nursery, inoculation, has_and_belongs_to_many :locations
  - finding MVC : run, sector, dog, harvester, started_at, stopped_at, found_at, comment, raw_weight, net_weight, surveyor
  - tiling MVC : tiling_at (day), tooling, row, comment, operator
  - mowing MVC : mowing_at (day), tooling, row, comment, operator
  - prunning MVC : prunning_at (day), architecture, row, comment, pruner
  - irrigation namespace
    - sector MVC : name, rows, admission, tertiary, description
    - admission MVC : tap type, diameter, pressure
    - tertiary MVC : diameter, flow, pressure, spacing, dispenser, has_flush_valve, secondary
    - primary MVC : diameter, flow, pressure
    - secondary MVC : diameter, flow, pressure, primary
    - dispensers MVC : brand, name, radius, is_regulated
  - fertilization namespace
    - formula MVC : nursery, name, description, density, weight_in_g
    - tool MVC : name, description
  - treatment namespace
    - family MVC : name, description
    - tool MVC : name, description
    - formula MVC : family, molecule, comment
  - planting namespace
    - orchard MVC : name, gis, description, farm
    - parcel MVC : name, gis, description, orchard
    - row MVC : name, gis, description, parcel
    - location MVC : name, gis, description, row, has_and_belongs_to_many :plantings
    - species MVC : name, description
    - nursery MVC : name, description
    - inoculation MVC : name, description
  - harvest namespace
    - run MVC : sector, dog, harvester, started_at, stopped_at, comment, raw_weight, net_weight, surveyor
    - dog MVC : name, born_at, description
    - sector MVC : name, rows, description
  - tiling namespace
    - tool MVC : name, description
  - mowing namespace
    - tool MVC : name, description
  - prunning namespace
    - architecture MVC : name, description
    - pruner MVC : adds specific pruners from outside services companies to the farm's users with pruning rights
- measure : a namespace to manage the data collected from various sources
  - observation MVC : type, location, observation_at, comment, observer
  - observation namespace
    - type MVC : name (faunistic, floristic, infrastuctural, phenological, abiotictical, biotictical), description
  - soil_analysis
  - soil_resistivity
  - soil_moisture
  - meteorological
  - plant_electrophysiology
  - multispectral
