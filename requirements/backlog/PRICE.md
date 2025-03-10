I need a strategy to build our weekly price list.
We want to integrate in the app our old excel process of observing the market prices to build our price list.
To do that, we need to create an MVC for managing MarketPriceRecord, MarketPlace, Channel and Price.
Integrate all that in a dedicated accordion menu.

## MarketPriceRecord
- published_at
- source (RNM or maillist or text message etc..) need to reference a more complex table with instructions on how to get the source and list standards?
- market_place_id references market_place
- avg_price_per_kg
- min_price_per_kg
- max_price_per_kg
- extra_price_per_kg
- c1_price_per_kg
- c2_price_per_kg
- c3_price_per_kg
- quantities_presented_per_kg
- quantities_sold_per_kg

## MarketPlace
- name (Sarlat, Martin Houette, Marine Gallois, Richerenche etc...)
- description (Description of the market place)
- truffle_source (from Spanish producers, from various french producers, from wholesellers, producer themself etc...)
- region (Touraine, Sud Est, Sud Ouest, Nouvelle Aquitaine etc..)
- country (France, Espagne, etc..)
- main_customer (Individuals, Restaurants, Distributors, transformers, importers etc...)

## Channel
- name (Sarlat, Martin Houette, Marine Gallois, Richerenche etc...)
- description (Description of the channel)

## Price
- applicable_at (week, year)
- channel_id (references Channel)
- extra_price_per_kg
- c1_price_per_kg
- c2_price_per_kg
- c3_price_per_kg

## Places (Market Places)
### Main view (index):
- Responsive grid of cards showing market places
- Search bar with filters (using Flowbite's search input)
- Quick action buttons on each card
### Show view:
- Tabs component for different aspects (Details, History, Statistics)
- Location information with a map integration
- Status badge showing if market is active/inactive
### Form (new/edit):
- Multi-step form using Flowbite's stepper
- Location picker with address validation
- Toggle switches for market status

## Price Records
### Main view:
- Data table with sorting and filtering
- Date range picker for historical data
### Show view:
- Price trend charts using Chartkick
- Detailed information in a card layout
- Related records in a sidebar
### Form:
- Smart form with dynamic fields
- Market place selector (dropdown) with a create option that opens a modal to create a new market place
- Price input with validation

## Channels
### Main view:
- List group showing distribution channels
- Status indicators using badges
- Quick filters using button group
### Show view:
- Channel metrics in stat cards
- Associated markets in a responsive grid
- Activity timeline
### Form:
- Single page form with sections
- Market place associations (multi-select)
- Channel type selector (radio buttons)

## Prices
### Main view:
- Pricing table with comparison features
- Filter by market/channel
- Bulk action toolbar
### Show view:
- Price breakdown in cards
- Historical changes timeline
- Related price records
### Form:
- Dynamic pricing form
- Market and channel selectors
- Effective date picker

## Common Elements Across All Sections:
- Breadcrumb navigation
- Consistent header with action buttons
- Toast notifications for actions
- Loading states using Flowbite spinners
- Mobile-responsive layouts
- Error handling with alert components