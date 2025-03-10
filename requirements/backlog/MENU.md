Add the following menu items :
- link : home icon : Dashboard
- separator
- link : qr-code icon : Harvesting Runs : app/controllers/harvesting_runs_controller.rb
- link : calendar-month icon : Harvesting Sectors : #
- link : scale-balanced icon : Intakes : app/controllers/intakes_controller.rb

Add the following menu items, just after the previous ones :
- separator
- link : store icon : Stocks : #
- link : euro icon : Pricing : app/controllers/market/prices_controller.rb
- link : cart icon : Orders : #
- link : cash-register icon : Sales : #

Add the following menu items, just after the previous ones :
- separator
- accordion : receipt icon : Sales Management
- link : Products : #
- link : Customers : #
- link : Bilings : #
- accordion : filter-dollar icon : Market Management
- link : Places : app/controllers/market/places_controller.rb
- link : Segments : app/controllers/market/segments_controller.rb
- link : Prices Records : app/controllers/market/price_records_controller.rb
- link : Channels : app/controllers/market/channels_controller.rb

Add the following menu items, just after the previous ones :
- separator
- accordion : cart-pie icon : Production
- link : Findings : app/controllers/analysis/findings_controller.rb
- link : Weights : app/controllers/analysis/weights_controller.rb
- link : Harvests : app/controllers/analysis/harvests_controller.rb
- accordion : map-pin-alt icon : Topology
- link : Parcels : app/controllers/topology/parcels_controller.rb
- link : Locations : #

Then at the bottom of the menu, like in the flowbite example : 
- Preferences : no text, just the pref icon leading to app/controllers/settings_controller.rb
- Settings : no text, just the wheel icon, a placeholder #
- Lang : the flag of the selected language