# frozen_string_literal: true

# == Schema Information
#
# Table name: hub_admin_permission_audits
#
#  id             :bigint           not null, primary key
#  action         :string           not null
#  change_type    :string           not null
#  controller     :string           not null
#  namespace      :string           not null
#  previous_state :jsonb
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  permission_id  :bigint
#  user_id        :bigint
#
# Indexes
#
#  idx_on_namespace_controller_action_a3a4846087       (namespace,controller,action)
#  index_hub_admin_permission_audits_on_permission_id  (permission_id)
#  index_hub_admin_permission_audits_on_user_id        (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (permission_id => hub_admin_permissions.id)
#  fk_rails_...  (user_id => hub_admin_users.id)
#

module Hub
  module Admin
    # Tracks changes to permissions for auditing purposes
    class PermissionAudit < ApplicationRecord
      self.table_name = 'hub_admin_permission_audits'
      
      #===========================================================================
      # Associations
      #===========================================================================
      
      belongs_to :permission, class_name: 'Hub::Admin::Permission', optional: true
      belongs_to :user, class_name: 'Hub::Admin::User', optional: true
      
      #===========================================================================
      # Validations
      #===========================================================================
      
      validates :namespace, :controller, :action, :change_type, presence: true
      validates :change_type, inclusion: { in: %w[created updated archived restored deleted] }
      
      #===========================================================================
      # Scopes
      #===========================================================================
      
      scope :latest, -> { order(created_at: :desc) }
      scope :for_permission, ->(permission) { where(permission_id: permission.id) }
      scope :for_namespace, ->(namespace) { where(namespace: namespace) }
      scope :for_controller, ->(controller) { where(controller: controller) }
      scope :for_action, ->(action) { where(action: action) }
      
      #===========================================================================
      # Class Methods
      #===========================================================================
      
      # Records an audit for a permission change
      # @param permission [Hub::Admin::Permission] the permission that changed
      # @param change_type [String] one of: created, updated, archived, restored, deleted
      # @param user [Hub::Admin::User, nil] the user who made the change (nil for system changes)
      # @param previous_state [Hash, nil] the previous state of the permission 
      # @return [Hub::Admin::PermissionAudit] the created audit record
      def self.record_change(permission, change_type, user: nil, previous_state: nil)
        create!(
          permission: permission,
          namespace: permission.namespace,
          controller: permission.controller,
          action: permission.action,
          change_type: change_type,
          user: user,
          previous_state: previous_state
        )
      end
      
      # Records system-initiated permission changes in bulk
      # @param permissions [Array<Hub::Admin::Permission>] the permissions that changed
      # @param change_type [String] the type of change that occurred
      # @return [Integer] the number of audit records created
      def self.record_bulk_change(permissions, change_type)
        audit_records = permissions.map do |permission|
          {
            permission_id: permission.id,
            namespace: permission.namespace,
            controller: permission.controller,
            action: permission.action,
            change_type: change_type,
            created_at: Time.zone.now,
            updated_at: Time.zone.now
          }
        end
        
        # Use insert_all for better performance with large numbers of records
        Hub::Admin::PermissionAudit.insert_all(audit_records) if audit_records.any?
        audit_records.size
      end
      
      # Returns a human-readable description of this audit entry
      # @return [String] a description of the change
      def description
        actor = user.present? ? "User #{user.full_name}" : "System"
        permission_path = "#{namespace}/#{controller}##{action}"
        
        case change_type
        when 'created'
          "#{actor} created permission #{permission_path}"
        when 'updated'
          "#{actor} updated permission #{permission_path}"
        when 'archived'
          "#{actor} archived permission #{permission_path}"
        when 'restored'
          "#{actor} restored permission #{permission_path}"
        when 'deleted'
          "#{actor} deleted permission #{permission_path}"
        else
          "#{actor} performed '#{change_type}' on permission #{permission_path}"
        end
      end
    end
  end
end
