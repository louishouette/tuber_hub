# TuberHub User Preferences

## Overview

The User Preferences system allows users to customize their TuberHub experience by storing and retrieving personalized settings. It's implemented as a flexible key-value store that can accommodate various types of preferences without requiring schema changes for new preference types.

## Architecture

### Database Schema

User preferences are stored in the `hub_admin_user_preferences` table with the following structure:

- `id`: Primary key
- `user_id`: Foreign key to `hub_admin_users`
- `key`: String identifier for the preference
- `value`: Text field storing JSON-serialized preference data
- `created_at`, `updated_at`: Timestamps

Indexes are created on `user_id` and `key` columns for performance.

### Models

#### `Hub::Admin::UserPreference`

The UserPreference model handles the storage and validation of user preferences:

```ruby
class Hub::Admin::UserPreference < ApplicationRecord
  # Associations
  belongs_to :user, class_name: 'Hub::Admin::User'

  # Validations
  validates :key, presence: true, uniqueness: { scope: :user_id }
  validates :value, presence: true
  validate :validate_value_format, if: -> { TYPED_PREFERENCES.key?(key) }

  # Scopes
  scope :by_key, ->(key) { where(key: key) }
  scope :system_preferences, -> { where("key LIKE ?", "system_%") }
  scope :user_defined, -> { where("key NOT LIKE ?", "system_%") }

  # Serialize value as JSON
  serialize :value, JSON

  # Common preference types and their expected data types
  TYPED_PREFERENCES = {
    'default_farm_id' => :integer,
    'items_per_page' => :integer
  }.freeze

  # Methods for updating, describing, and validating preferences
  # ...
end
```

#### `Hub::Admin::User` Extensions

The User model is extended with methods for managing preferences:

```ruby
class Hub::Admin::User < ApplicationRecord
  # Association
  has_many :user_preferences, dependent: :destroy

  # Preference methods
  def preference(key, default = nil)
    pref = user_preferences.by_key(key).first
    pref&.value || default
  end

  def set_preference(key, value)
    pref = user_preferences.by_key(key).first_or_initialize
    pref.update_value(value)
    pref
  end

  def delete_preference(key)
    pref = user_preferences.by_key(key).first
    return true unless pref.present?
    pref.destroy
  end

  def has_preference?(key)
    user_preferences.by_key(key).exists?
  end

  # Additional helper methods
  # ...
end
```

## Using User Preferences

### Setting Preferences

To set a user preference:

```ruby
# In a controller
Current.user.set_preference('items_per_page', 25)

# Or for a specific user
user = Hub::Admin::User.find(user_id)
user.set_preference('theme', 'dark')
```

### Getting Preferences

To retrieve a user preference with a default fallback value:

```ruby
# In a controller
items_per_page = Current.user.preference('items_per_page', 10)

# Or using the convenience method
items_per_page = Current.user.items_per_page # Default is 25
```

### Checking if a Preference Exists

```ruby
if Current.user.has_preference?('dashboard_layout')
  # Use the custom dashboard layout
else
  # Use the default layout
end
```

### Deleting Preferences

```ruby
Current.user.delete_preference('theme')
```

## Default Farm Preference

The default farm preference is a special case that integrates with TuberHub's farm context system:

```ruby
# Setting a default farm
farm = Hub::Admin::Farm.find(farm_id)
Current.user.set_default_farm(farm)

# Getting the default farm
default_farm = Current.user.default_farm

# Clearing the default farm
Current.user.clear_default_farm
```

The `CurrentFarm` concern checks for the default farm preference when determining the current farm context:

```ruby
def fetch_current_farm
  # First check session
  if session[:selected_farm_id].present?
    farm = Hub::Admin::Farm.find_by(id: session[:selected_farm_id])
    return farm if farm && Current.user.farms.include?(farm)
  end

  # Then check user's default farm preference
  default_farm = Current.user.default_farm
  return default_farm if default_farm.present?

  # Finally, fall back to the first farm the user has access to
  Current.user.farms.first
end
```

## System vs. User-Defined Preferences

System preferences are prefixed with `system_` and are typically managed by the application rather than directly by users. User-defined preferences can have any key that doesn't start with `system_`.

```ruby
# Get all system preferences
system_prefs = Current.user.system_preferences

# Get all user-defined preferences
user_prefs = Current.user.user_defined_preferences

# Check if a preference is a system preference
is_system = preference.system_preference? # Returns true if key starts with 'system_'
```

## Typed Preferences

The UserPreference model includes validation for common preference types:

```ruby
TYPED_PREFERENCES = {
  'default_farm_id' => :integer,
  'items_per_page' => :integer,
  'language' => :string,
  'timezone' => :string
}.freeze
```

When adding a new typed preference, add it to this constant to ensure proper validation.

## Language and Timezone Preferences

### Language Preference

The language preference determines the display language for the application interface. Currently, the application supports:

- English (EN) - Default
- French (FR) - Prepared for future implementation

To set a user's language preference:

```ruby
Current.user.set_preference('language', 'EN')
```

To retrieve a user's language preference:

```ruby
language = Current.user.preference('language', 'EN') # Default to English
```

### Timezone Preference

The timezone preference allows users to see dates and times in their local timezone:

```ruby
Current.user.set_preference('timezone', 'Europe/Paris')
```

To retrieve a user's timezone preference:

```ruby
timezone = Current.user.preference('timezone', 'UTC') # Default to UTC
```

This preference affects how dates and times are displayed throughout the application when using the appropriate helper methods.

## User Interface

The User Preferences are integrated directly into the user profile view. Users can access their preferences through their user profile page.

### Accessing User Preferences

1. Click on the user profile icon in the top navbar
2. Click on "My Profile" to access your profile page
3. Scroll down to the "User Preferences" section

The preferences are organized into categories with a tabbed interface:

- Farm Settings - Configure your default farm
- Interface Settings - Set display options like items per page
- Language - Choose your preferred language
- Timezone - Set your local timezone

## Adding New Preference Types

To add a new preference type:

1. If it's a common preference type that needs validation, add it to the `TYPED_PREFERENCES` constant in the UserPreference model.
2. Add convenience methods to the User model if needed.
3. Update the user show page to include UI for managing the new preference in the appropriate tab section.
4. Update this documentation.

## Best Practices

1. Always use the `preference` method with a sensible default value to avoid nil errors.
2. Use the typed preferences system for validation when appropriate.
3. Consider adding convenience methods to the User model for frequently accessed preferences.
4. Use system preferences (prefixed with `system_`) for application-managed settings.
5. Keep preference keys consistent and well-documented.
6. Use the `Time.zone.now` method for all time-related operations to ensure timezone awareness.

## Future Enhancements

- Improved UI for managing preferences
