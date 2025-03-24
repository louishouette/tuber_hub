# FIX: namespace organisation
- check that every namespace under Hub follows the structure detailed in @docs/tuber_hub/NAMESPACE_CREATION.md

# FEAT: User preferences
- create a UserPreference model referencing the Hub::Admin::User, key (string), and value (text) plus timestamps.
- In UserPreference, add belongs_to :user (Hub::Admin::User) and validate presence of key; implement an update_value method with info and debug logging.
- In the User model, add has_many :user_preferences, dependent: :destroy and a helper method to retrieve preferences with defaults.
- In the controllers, manage user preferences via strong parameters and add database indexing on the user id and key for performance.
- Leverage UserPreference model for user customizations including default farm

# FEAT: user activity logging
- log user activity

# FEAT: prepare for production
- Setup Kamal : security find-internet-password -a 'lmmh' -l 'Docker Credentials' -w for retrieving docker credentials
- Configure Active Storage : config/storage.yml 
- Configure Action Mailer 

# FEAT: displaying different layouts
- the following pages will be accessible only after loging in :
  - /club
  - Tuber HUB : https://hub.truffiere-de-cement.fr
  - Marketplace : https://marketplace.truffiere-de-cement.fr

# FEAT : notifications
- use https://github.com/excid3/noticed for handling notifications

# IDEAS:
- https://github.com/pay-rails/pay

# PROMPT: maintain a changelog
- apply the requested changes maintaining a changelog in the adequate file in @requirements/changelogs using @requirements/changelogs/generic.md as a template. Refer to the app documentation in @docs/tuber_hub for contextual functionnalities (like authorization for example)
