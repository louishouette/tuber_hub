# == Schema Information
#
# Table name: hub_admin_role_assignments
#
#  id            :bigint           not null, primary key
#  expires_at    :datetime
#  global        :boolean          default(TRUE)
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  farm_id       :bigint
#  granted_by_id :bigint           not null
#  revoked_by_id :bigint
#  role_id       :bigint           not null
#  user_id       :bigint           not null
#
# Indexes
#
#  idx_role_assignments_user_role_farm                (user_id,role_id,farm_id) UNIQUE
#  index_hub_admin_role_assignments_on_farm_id        (farm_id)
#  index_hub_admin_role_assignments_on_granted_by_id  (granted_by_id)
#  index_hub_admin_role_assignments_on_revoked_by_id  (revoked_by_id)
#  index_hub_admin_role_assignments_on_role_id        (role_id)
#  index_hub_admin_role_assignments_on_user_id        (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (farm_id => hub_admin_farms.id)
#  fk_rails_...  (granted_by_id => hub_admin_users.id)
#  fk_rails_...  (revoked_by_id => hub_admin_users.id)
#  fk_rails_...  (role_id => hub_admin_roles.id)
#  fk_rails_...  (user_id => hub_admin_users.id)
#
module Hub
  module Admin
    class RoleAssignment < ApplicationRecord
      # Associations
      belongs_to :user, class_name: 'Hub::Admin::User'
      belongs_to :role
      belongs_to :granted_by, class_name: 'Hub::Admin::User', optional: true
      belongs_to :farm, class_name: 'Hub::Admin::Farm', optional: true
      
      # Validations - ensure uniqueness of role assignments while respecting farm scoping
      validates :user_id, uniqueness: { scope: [:role_id, :farm_id], message: 'already has this role with the specified scope' }

      # Custom validation to ensure proper farm-role relationships
      validate :validate_farm_global_settings
      
      # Scopes
      scope :active, -> { where("expires_at IS NULL OR expires_at > ?", Time.zone.now) }
      scope :expired, -> { where("expires_at IS NOT NULL AND expires_at <= ?", Time.zone.now) }
      
      # Methods
      def expired?
        expires_at.present? && expires_at <= Time.zone.now
      end

      # Returns whether this role assignment is global (not farm-specific)
      def global?
        global == true || farm_id.nil?
      end

      # Returns whether this role assignment is farm-specific
      def farm_specific?
        !global? && farm_id.present?
      end

      private

      # Validates the farm vs. global settings are consistent
      def validate_farm_global_settings
        if global? && farm_id.present?
          errors.add(:global, 'cannot be true when a farm is assigned')
        end

        if !global? && farm_id.blank?
          errors.add(:farm_id, 'must be present for farm-specific role assignments')
        end
      end
      
      def active?
        !expired?
      end
      
      def revoke!(revoking_user = nil)
        update(expires_at: Time.zone.now, revoked_by: revoking_user)
      end
    end
  end
end
