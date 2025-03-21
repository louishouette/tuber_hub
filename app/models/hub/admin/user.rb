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

      normalizes :email_address, with: ->(e) { e.strip.downcase }
      normalizes :first_name, :last_name, :job_title, with: ->(value) { value.to_s.strip.presence }
      normalizes :phone_number, with: ->(value) { value.to_s.strip.gsub(/\D/, '').presence }

      validates :first_name, :last_name, presence: true, on: :update

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
    end
  end
end
