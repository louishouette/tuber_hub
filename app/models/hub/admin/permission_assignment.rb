# == Schema Information
#
# Table name: hub_admin_permission_assignments
#
#  id            :bigint           not null, primary key
#  expires_at    :datetime
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  granted_by_id :bigint           not null
#  permission_id :bigint           not null
#  revoked_by_id :bigint
#  role_id       :bigint           not null
#
# Indexes
#
#  idx_permission_assignments_lookup                        (role_id,permission_id)
#  index_hub_admin_permission_assignments_on_expires_at     (expires_at)
#  index_hub_admin_permission_assignments_on_granted_by_id  (granted_by_id)
#  index_hub_admin_permission_assignments_on_permission_id  (permission_id)
#  index_hub_admin_permission_assignments_on_revoked_by_id  (revoked_by_id)
#  index_hub_admin_permission_assignments_on_role_id        (role_id)
#
# Foreign Keys
#
#  fk_rails_...  (granted_by_id => hub_admin_users.id)
#  fk_rails_...  (permission_id => hub_admin_permissions.id)
#  fk_rails_...  (revoked_by_id => hub_admin_users.id)
#  fk_rails_...  (role_id => hub_admin_roles.id)
#
module Hub
  module Admin
    class PermissionAssignment < ApplicationRecord
      # Associations
      belongs_to :role
      belongs_to :permission
      belongs_to :granted_by, class_name: 'Hub::Admin::User', optional: true
      
      # Validations
      validates :role_id, uniqueness: { scope: :permission_id, message: 'already has this permission' }
      
      # Scopes
      scope :active, -> { where("expires_at IS NULL OR expires_at > ?", Time.zone.now) }
      scope :expired, -> { where("expires_at IS NOT NULL AND expires_at <= ?", Time.zone.now) }
      
      # Methods
      def expired?
        expires_at.present? && expires_at <= Time.zone.now
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
