# Domain-Driven Design Structure

## Authentication
Handles user identity and access control within the system:
- User management with role-based access (guest, employee, manager, admin)
- Permission management for harvesting and surveying activities
- Secure session handling and authentication
- Password management and security

## Topology
Manages the physical organization of truffle farms:
- Hierarchical structure: Farm → Orchard → Parcel → Row → Location
- Location tracking as the atomic unit for truffle findings
- Harvesting sector organization for collection management
- Spatial relationship management between different farm elements

## Operations
Coordinates daily farming activities and resource management:
- Truffle-hunting dog management and assignment
- Irrigation system monitoring and control
- Meteorological data tracking for optimal growing conditions
- Operational resource allocation and scheduling

## Plantation
Oversees tree management and truffle cultivation:
- Tree species catalog and management
- Inoculation process tracking (truffle spore introduction)
- Provider relationship management
- Planting lifecycle monitoring

## Observation
Tracks truffle discovery and harvesting activities:
- Detailed finding records (depth, weight, location)
- Harvesting run management and coordination
- Performance tracking for dogs and surveyors
- Quality control and yield monitoring

```sh
app/
├── authentication/
│   ├── models/
│   │   └── user.rb
│   ├── views/...
│   └── controllers/
│       └── users_controller.rb
│
├── topology/
│   ├── models/
│   │   ├── orchard.rb
│   │   ├── parcel.rb
│   │   ├── row.rb
│   │   ├── location.rb
│   │   ├── location_planting.rb
│   │   ├── harvesting_sector.rb
│   │   └── farm.rb
│   ├── views/...
│   └── controllers/
│       ├── orchards_controller.rb
│       ├── parcels_controller.rb
│       ├── rows_controller.rb
│       ├── locations_controller.rb
│       ├── harvesting_sectors_controller.rb
│       └── farms_controller.rb
│
├── operations/
│   ├── models/
│   │   ├── dog.rb
│   │   ├── irrigation.rb
│   │   └── meteo.rb
│   ├── views/...
│   └── controllers/
│       ├── dogs_controller.rb
│       ├── irrigations_controller.rb
│       └── meteos_controller.rb
│
├── plantation/
│   ├── models/
│   │   ├── planting.rb
│   │   ├── species.rb
│   │   ├── innoculation.rb
│   │   └── provider.rb
│   ├── views/...
│   └── controllers/
│       ├── plantings_controller.rb
│       ├── species_controller.rb
│       ├── innoculations_controller.rb
│       └── providers_controller.rb
│
├── observation/
│   ├── models/
│   │   ├── harvesting_run.rb
│   │   └── finding.rb
│   ├── views/...
│   └── controllers/
│       ├── harvesting_runs_controller.rb
│       └── findings_controller.rb
│
└── core/
    ├── models/
    │   ├── application_record.rb
    │   ├── session.rb
    │   └── current.rb
    └── controllers/
        ├── application_controller.rb
        └── sessions_controller.rb
```