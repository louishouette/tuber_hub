# == Schema Information
#
# Table name: hub_admin_users
#
#  id                 :bigint           not null, primary key
#  active             :boolean          default(TRUE), not null
#  current_sign_in_ip :string
#  email_address      :string           not null
#  first_name         :string
#  job_title          :string
#  last_name          :string
#  last_sign_in_at    :datetime
#  notes              :text
#  password_digest    :string           not null
#  phone_number       :string
#  sign_in_count      :integer
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#
# Indexes
#
#  index_hub_admin_users_on_email_address  (email_address) UNIQUE
#
module Hub
  module Admin
    class User < ApplicationRecord
      self.table_name = 'hub_admin_users'
      
      has_secure_password
      has_many :sessions, dependent: :destroy
      
      # Notifications association removed
      
      # Role associations
      has_many :role_assignments, dependent: :destroy
      has_many :roles, through: :role_assignments
      
      # Permission grants associations - for tracking who granted permissions
      has_many :granted_role_assignments, class_name: 'RoleAssignment', foreign_key: 'granted_by_id'
      has_many :granted_permission_assignments, class_name: 'PermissionAssignment', foreign_key: 'granted_by_id'
      
      # Farm associations
      has_many :farm_users, dependent: :destroy
      has_many :farms, through: :farm_users
      
      # User preferences association
      has_many :user_preferences, dependent: :destroy

      normalizes :email_address, with: ->(e) { e.strip.downcase }
      normalizes :first_name, :last_name, :job_title, with: ->(value) { value.to_s.strip.presence }
      normalizes :phone_number, with: ->(value) { value.to_s.strip.gsub(/\D/, '').presence }

      validates :first_name, :last_name, presence: true, on: :update
      validate :must_have_farm, on: :create
      validate :must_have_role, on: :create

      # Custom validation to ensure user has at least one farm
      def must_have_farm
        errors.add(:base, 'User must be associated with at least one farm') if farm_id.blank?
      end

      # Custom validation to ensure user has at least one role
      def must_have_role
        errors.add(:base, 'User must be assigned at least one role') if role_id.blank?
      end

      # Virtual attributes for farm assignment during user creation
      attr_accessor :farm_id, :role_id

      def full_name
        [ first_name, last_name ].compact_blank.join(" ")
      end
      
      # Role and permission methods
      def admin?
        # Case-insensitive check for admin role
        roles.where('LOWER(name) = ?', 'admin').exists?
      end
      
      def has_role?(role_name)
        # Case-insensitive role check
        roles.where('LOWER(name) = ?', role_name.downcase).exists?
      end
      
      # Check if user can perform action on controller in namespace
      # @param action [String, Symbol] the action to check permission for
      # @param namespace [String, Symbol] the namespace to check permission in
      # @param controller [String, Symbol] the controller to check permission for
      # @param farm [Hub::Admin::Farm, nil] optional farm to check farm-specific permissions for
      # @param use_preloaded [Boolean] whether to use preloaded permissions if available
      # @return [Boolean] whether user has permission
      def can?(action, namespace, controller, farm: nil, use_preloaded: false)
        return true if admin?
        
        # Delegate to the centralized authorization service
        AuthorizationService.user_has_permission?(self, namespace, controller, action, farm: farm, use_preloaded: use_preloaded)
      end

      # Check if user has a farm-specific role
      # @param role_name [String, Symbol] the role name to check for
      # @param farm [Hub::Admin::Farm] the farm to check roles for
      # @return [Boolean] whether user has the role in the specific farm context
      def has_farm_role?(role_name, farm)
        return false if farm.nil?
        role_assignments
          .joins(:role)
          .where(farm: farm, global: false)
          .where('LOWER(hub_admin_roles.name) = ?', role_name.to_s.downcase)
          .exists?
      end
      
      # Check if user account is active
      def active?
        active
      end
      
      # Authenticate a user with email and password - follows Rails 8 pattern
      # @param params [ActionController::Parameters] params containing email_address and password
      # @return [Hub::Admin::User, nil] the authenticated user or nil if authentication failed
      def self.authenticate_by(params)
        # Use normalized email_address (auto-downcased and stripped by normalizes)
        user = find_by(email_address: params[:email_address])
        
        # Only authenticate active users
        return nil unless user&.active?
        
        # Verify password using has_secure_password's authenticate method
        user.authenticate(params[:password]) ? user : nil
      end
      
      # Farm related methods
      
      # Add user to a farm
      def add_to_farm(farm)
        return nil unless farm
        farm_users.find_or_create_by(farm: farm)
        farm
      end
      
      # User preference methods
      
      # Get a user preference with optional default value
      # @param key [String] The preference key
      # @param default [Object] Default value if preference doesn't exist
      # @return [Object] The preference value or default
      def preference(key, default = nil)
        pref = user_preferences.by_key(key).first
        pref&.value || default
      end
      
      # Set a user preference
      # @param key [String] The preference key
      # @param value [Object] The value to store
      # @return [Hub::Admin::UserPreference] The updated or created preference
      def set_preference(key, value)
        pref = user_preferences.by_key(key).first_or_initialize
        pref.update_value(value)
        pref
      end
      
      # Delete a user preference
      # @param key [String] The preference key to delete
      # @return [Boolean] Whether the deletion was successful
      def delete_preference(key)
        pref = user_preferences.by_key(key).first
        return true unless pref.present?
        pref.destroy
      end
      
      # Check if a preference exists
      # @param key [String] The preference key to check
      # @return [Boolean] Whether the preference exists
      def has_preference?(key)
        user_preferences.by_key(key).exists?
      end
      
      # Get all user-defined preferences (not system preferences)
      # @return [ActiveRecord::Relation] Collection of user preferences
      def user_defined_preferences
        user_preferences.user_defined
      end
      
      # Get all system preferences
      # @return [ActiveRecord::Relation] Collection of system preferences
      def system_preferences
        user_preferences.system_preferences
      end
      
      # Get the user's default farm
      # @return [Hub::Admin::Farm, nil] The default farm or nil if not set
      def default_farm
        farm_id = preference('default_farm_id')
        return nil unless farm_id.present?
        
        # Only return farms the user has access to
        farms.find_by(id: farm_id)
      end
      
      # Set the user's default farm
      # @param farm [Hub::Admin::Farm] The farm to set as default
      # @return [Boolean] Whether the operation was successful
      def set_default_farm(farm)
        return false unless farm && farms.include?(farm)
        set_preference('default_farm_id', farm.id)
        true
      end
      
      # Clear the user's default farm setting
      # @return [Boolean] Whether the operation was successful
      def clear_default_farm
        delete_preference('default_farm_id')
      end
      
      # Get the number of items to display per page
      # @return [Integer] The number of items per page
      def items_per_page
        preference('items_per_page', 25).to_i
      end
      
      # Check if notifications are enabled
      # @return [Boolean] Whether notifications are enabled
      def notifications_enabled?
        preference('notifications_enabled', true) == true
      end
    end
  end
end
