# Tuber Ecosystem of apps
FBH Invest is a farming company dedicated to the production of black truffles in the Loire Valley. It distributes its production under the brand "Truffière de Cément".

## Redirecting all domains
All available domains will redirect to the main one : https://www.truffiere-de-cement.fr

## Tuber SHOP
https://www.truffiere-de-cement.fr
The brand website will serve :
- a homepage with a CTA for gathering leads 
- a /shop section for selling truffles
- the following public sections : /blog, /news, /about, /contact and /job
- a /club section for private stories and private figures
- a discrete 'connect' link to the ERP (if already connected, don't display 'connect' but 'Tuber HUB')

## Tuber HUB
https://hub.truffiere-de-cement.fr
The internal ERP tool to manage ressources and operations and to create reports. 
Its data is made available to other apps throught its versioned API at api.truffiere-de-cement.fr/v2
- core : the namespace to manage the main elements
  - farm
  - season
  - production
- cultivation : the namespace to manage the cultivation elements
  - irrigation namespace
  - fertilization namespace
  - treatment namespace
  - planting namespace
  - harvest namespace
  - tiling namespace
  - mowing namespace
  - prunning namespace
- measure : a namespace to manage the data collected from various sources
  - observation : faunistic, floristic, infrastuctural, phenological, abiotictical, biotictical
  - soil_analysis
  - soil_resistivity
  - soil_moisture
  - meteorological
  - plant_electrophysiology
  - multispectral
- admin : the namespace to manage the admin elements
  - user
  - role
  - permission

## Tuber MARKETPLACE
https://marketplace.truffiere-de-cement.fr
A reserved access to the commercial partners where they can find everything about the week prices, their past orders, invoices, track their order and see their allocated quantities. It's their endpoint for business relation.

## Tuber SCOUT
http://scout.truffiere-de-cement.fr
The mobile website, a responsive frontend to a simple surveying on-field system, to report on truffle findings.
An link to the iOS and Android app version of Tuber SCOUT will be available at : http://scout.truffiere-de-cement.fr/app
