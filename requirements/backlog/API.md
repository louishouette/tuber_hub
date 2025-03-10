# Proposed strategy for managing and presenting the agricultural data:

Considering there is roughly :
- 3 domains
- 15 orchards
- 100 parcels
- 300 harvestings sectors
- 1 000 rows
- 50 000 locations
- 80 000 plantings

1. Data Architecture & API Design:
- Implement a hierarchical API structure: Domain -> Orchard -> Parcel -> Harvesting Sector -> Row -> Location -> Planting
- Use JSON:API specification for standardized responses and efficient data loading
- Implement pagination and cursor-based navigation for large collections (especially for locations and plantings)

2. Performance Optimizations:
- Implement eager loading to prevent N+1 queries
- Use counter caches for frequently accessed counts
- Implement Russian Doll caching for nested resources
- Use background jobs for heavy data processing tasks

3. Mobile-First UI Strategy (iPhone-specific):
- Implement infinite scroll for large lists
- Use lazy loading for images and heavy content
- Implement pull-to-refresh patterns
- Use Flowbite components optimized for mobile viewing

```ruby
{{ ... }}

  # API Routes
  namespace :api do
    namespace :v1 do
      resources :domains do
        resources :orchards do
          resources :parcels do
            resources :harvesting_sectors do
              resources :rows do
                resources :locations do
                  resources :plantings, shallow: true
                end
              end
            end
          end
        end
      end
      
      # Flat routes for direct access when hierarchy is known
      resources :orchards, only: [:index, :show]
      resources :parcels, only: [:index, :show]
      resources :harvesting_sectors, only: [:index, :show]
      resources :rows, only: [:index, :show]
      resources :locations, only: [:index, :show] do
        collection do
          get :search
        end
      end
      resources :plantings, only: [:index, :show]
    end
  end

{{ ... }}
```

1. API Structure & Controllers
```ruby
# Proposed structure for API controllers
module Api
  module V1
    class BaseController < ApplicationController
      include Pagy::Backend
      
      private
      
      def paginate(relation)
        pagy(relation, items: params[:per_page] || 20)
      end
      
      def expect_params(*keys)
        params.expect(*keys)
      end
    end
  end
end
```

2. Model Relationships:
```ruby
class Domain < ApplicationRecord
  has_many :orchards
  has_many :parcels, through: :orchards
end

class Orchard < ApplicationRecord
  belongs_to :domain
  has_many :parcels
  has_many :harvesting_sectors, through: :parcels
end
```

3. Performance Optimizations:
- Add counter caches to relevant associations
- Implement Russian Doll caching
- Use includes for eager loading related records
- Add database indexes for frequently queried columns

4. Mobile UI Components (using Flowbite):
- Implement infinite scroll lists for large collections
- Use skeleton loading states for better UX
- Implement pull-to-refresh functionality
- Use compact card layouts for dense data display

5. Caching Strategy:
- Use Redis for caching
- Implement fragment caching for partial updates
- Cache counts and aggregated data
- Use ETags for API responses

6. Security Measures:
- Implement rate limiting
- Use JWT for API authentication
- Implement proper CORS policies
- Add request throttling for heavy endpoints

# Tuber Scout API Documentation

## Authentication
All API endpoints require authentication. Include your API token in the Authorization header:
```
Authorization: Bearer your-api-token
```

## Endpoints

### Orchards
- `GET /api/v1/orchards` - List all orchards
- `GET /api/v1/orchards/:id` - Get a specific orchard

### Parcels
- `GET /api/v1/parcels` - List all parcels
- `GET /api/v1/parcels/:id` - Get a specific parcel

### Harvesting Sectors
- `GET /api/v1/harvesting_sectors` - List all harvesting sectors
- `GET /api/v1/harvesting_sectors/:id` - Get a specific harvesting sector

### Rows
- `GET /api/v1/rows` - List all rows
- `GET /api/v1/rows/:id` - Get a specific row

### Locations
- `GET /api/v1/locations` - List all locations
- `GET /api/v1/locations/:id` - Get a specific location
- `GET /api/v1/locations/search` - Search locations by criteria

### Plantings
- `GET /api/v1/plantings` - List all plantings
- `GET /api/v1/plantings/:id` - Get a specific planting

## Hierarchical Access
For hierarchical access, use the nested routes:

### Domains
- `GET /domains/:domain_id/orchards` - List orchards in a domain
- `GET /domains/:domain_id/orchards/:id` - Get a specific orchard in a domain

### Orchards
- `GET /domains/:domain_id/orchards/:orchard_id/parcels` - List parcels in an orchard
- `GET /domains/:domain_id/orchards/:orchard_id/parcels/:id` - Get a specific parcel in an orchard

### Parcels
- `GET /domains/:domain_id/orchards/:orchard_id/parcels/:parcel_id/harvesting_sectors` - List harvesting sectors in a parcel
- `GET /domains/:domain_id/orchards/:orchard_id/parcels/:parcel_id/harvesting_sectors/:id` - Get a specific harvesting sector in a parcel

### Harvesting Sectors
- `GET /domains/:domain_id/orchards/:orchard_id/parcels/:parcel_id/harvesting_sectors/:harvesting_sector_id/rows` - List rows in a harvesting sector
- `GET /domains/:domain_id/orchards/:orchard_id/parcels/:parcel_id/harvesting_sectors/:harvesting_sector_id/rows/:id` - Get a specific row in a harvesting sector

## Response Format
All responses are in JSON format. Successful responses have the following structure:
```json
{
  "data": {
    "id": "1",
    "type": "orchard",
    "attributes": {
      "name": "Example Orchard",
      "created_at": "2024-12-24T14:00:00Z",
      "updated_at": "2024-12-24T14:00:00Z"
    }
  }
}
```

## Error Responses
Error responses follow the JSON API specification:
```json
{
  "errors": [
    {
      "status": "404",
      "title": "Not Found",
      "detail": "The requested resource could not be found."
    }
  ]
}
```

## Rate Limiting
API requests are limited to 1000 requests per hour per API token. Rate limit information is included in the response headers:
```
X-RateLimit-Limit: 1000
X-RateLimit-Remaining: 999
X-RateLimit-Reset: 1640361600
```

Would you like me to proceed with implementing any specific part of this strategy? I can help you with:
- Setting up the API controllers and routes
- Implementing the model relationships
- Setting up the caching infrastructure
- Creating mobile-optimized views with Flowbite
- Implementing the security measures
