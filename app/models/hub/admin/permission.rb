# == Schema Information
#
# Table name: hub_admin_permissions
#
#  id          :bigint           not null, primary key
#  action      :string
#  controller  :string
#  description :text
#  namespace   :string
#  status      :string
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
# Indexes
#
#  idx_permissions_lookup                 (namespace,controller,action,status)
#  index_hub_admin_permissions_on_status  (status)
#
module Hub
  module Admin
    class Permission < ApplicationRecord
      # Constants for permission statuses
      STATUSES = {
        active: 'active',
        legacy: 'legacy'
      }.freeze

      # Associations
      has_many :permission_assignments, dependent: :destroy
      has_many :roles, through: :permission_assignments
      
      # Validations
      validates :namespace, :controller, :action, presence: true
      validates :namespace, uniqueness: { scope: [:controller, :action] }
      validates :status, inclusion: { in: STATUSES.values }
      
      # Default values
      attribute :status, :string, default: STATUSES[:active]
      
      # Scopes
      scope :by_namespace, ->(namespace) { where(namespace: namespace) }
      scope :by_controller, ->(controller) { where(controller: controller) }
      scope :by_action, ->(action) { where(action: action) }
      scope :active, -> { where(status: STATUSES[:active]) }
      scope :legacy, -> { where(status: STATUSES[:legacy]) }
      
      # Callback to normalize values
      before_validation :normalize_values
      
      # Full identifier for the permission (useful for display and debugging)
      def full_identifier
        "#{namespace}/#{controller}##{action}"
      end

      # Mark permission as legacy
      def mark_as_legacy!
        update(status: STATUSES[:legacy])
      end

      # Mark permission as active
      def mark_as_active!
        update(status: STATUSES[:active])
      end

      # Check if permission is legacy
      def legacy?
        status == STATUSES[:legacy]
      end

      # Check if permission is active
      def active?
        status == STATUSES[:active]
      end

      # Class method to find all permissions that should be legacy
      # (controller no longer exists in application)
      def self.find_legacy_permissions
        current_controller_actions = []
        
        # Get all current controller/actions from routes
        Rails.application.routes.routes.each do |route|
          next if route.defaults[:controller].blank? || route.defaults[:action].blank?
          
          parts = route.defaults[:controller].split('/')
          namespace = parts.size > 1 ? parts[0..-2].join('/') : ''
          controller = parts.last
          action = route.defaults[:action]
          
          # Skip rails/ namespaces
          next if namespace.start_with?('rails/')
          
          current_controller_actions << {
            namespace: namespace,
            controller: controller,
            action: action
          }
        end
        
        # Find all active permissions that aren't in the current routes
        active.to_a.reject do |permission|
          current_controller_actions.any? do |ca|
            ca[:namespace] == permission.namespace &&
            ca[:controller] == permission.controller &&
            ca[:action] == permission.action
          end
        end
      end

      # Mark all permissions that are no longer valid as legacy
      def self.mark_legacy_permissions!
        legacy_permissions = find_legacy_permissions
        count = 0
        
        legacy_permissions.each do |permission|
          if permission.mark_as_legacy!
            count += 1
          end
        end
        
        count
      end
      
      private
      
      def normalize_values
        self.namespace = namespace.to_s.strip.downcase if namespace.present?
        self.controller = controller.to_s.strip.downcase if controller.present?
        self.action = action.to_s.strip.downcase if action.present?
      end
    end
  end
end
