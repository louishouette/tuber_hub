# Planting Dates Update Requirements

## Context
Each parcel's planted_at should reflect the oldest planting date among its locations.
Each location can have multiple plantings (historical record in case of replanting).
We use location.actual_planting to get the current active planting.

## Parcel and Row Planting Dates (dd/mm/yy)

### Single Date Parcels
- F: 11/04/18
- H: 17/04/18
- G: 23/04/18
- I: 27/04/18
- L: 29/11/18
- B1: 20/02/19
- B2: 06/03/19
- A1: 12/03/19
- C: 24/01/20
- E2: 04/03/20
- E1: 21/04/20
- A2: 05/05/20
- LP: 31/03/21

### Multi-Row Parcels
Parcel J:
- R1 to R9 + R11 + R13: 16/05/18
- R10 + R12 to R28: 22/11/18

Parcel K:
- R0 to R17: 11/01/19
- R18 to R23: 24/01/20

### Special Cases
Parcel D1:
- All rows except R0: 02/03/20
- R0: 13/02/23

Parcel D2:
- All rows except R0: 21/01/20
- R0: 13/02/23