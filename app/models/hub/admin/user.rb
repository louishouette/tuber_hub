# == Schema Information
#
# Table name: hub_admin_users
#
#  id              :bigint           not null, primary key
#  active          :boolean          default(TRUE), not null
#  email_address   :string           not null
#  first_name      :string
#  last_name       :string
#  last_sign_in_at :datetime
#  password_digest :string           not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
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
      
      # Role associations
      has_many :role_assignments, dependent: :destroy
      has_many :roles, through: :role_assignments
      
      # Permission grants associations - for tracking who granted permissions
      has_many :granted_role_assignments, class_name: 'RoleAssignment', foreign_key: 'granted_by_id'
      has_many :granted_permission_assignments, class_name: 'PermissionAssignment', foreign_key: 'granted_by_id'

      normalizes :email_address, with: ->(e) { e.strip.downcase }
      normalizes :first_name, :last_name, with: ->(value) { value.to_s.strip.presence }

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
      def can?(action, namespace, controller)
        # Admin can do everything
        return true if admin?
        
        # Return false if user has no roles
        return false if roles.empty?
        
        # Cache the permission check for better performance
        permission_key = "user_#{id}_permission_#{namespace}:#{controller}:#{action}"
        Rails.cache.fetch(permission_key, expires_in: 1.hour) do
          # Check if user has role with permission for this action
          # Account for both unlimited and non-expired permissions
          roles.joins(permission_assignments: :permission)
            .where(
              hub_admin_permissions: {
                namespace: namespace.to_s,
                controller: controller.to_s,
                action: action.to_s,
                status: 'active'
              }
            )
            .where(
              hub_admin_permission_assignments: { expires_at: nil }
            )
            .or(
              roles.joins(permission_assignments: :permission)
                .where(
                  hub_admin_permissions: {
                    namespace: namespace.to_s,
                    controller: controller.to_s,
                    action: action.to_s,
                    status: 'active'
                  }
                )
                .where('hub_admin_permission_assignments.expires_at > ?', Time.zone.now)
            )
            .exists?
        end
      end
      
      # Check if user account is active
      def active?
        active
      end
    end
  end
end
