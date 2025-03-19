# Be sure to restart your server when you modify this file.

# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "bin/rails g active_record:session_migration")
# Rails.application.config.session_store :active_record_store

# Use cookie-based session storage with strong security settings
Rails.application.config.session_store :cookie_store, 
  key: '_tuber_hub_session',
  expire_after: 2.weeks,
  secure: Rails.env.production?, # Only transmitted over HTTPS in production
  httponly: true, # Not accessible via JavaScript
  same_site: :lax # Restricts cross-site requests
