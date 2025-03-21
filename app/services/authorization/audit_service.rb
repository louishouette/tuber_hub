# frozen_string_literal: true

module Authorization
  # Service for auditing permission changes and retrieving historical permission data
  class AuditService < BaseService
    #===========================================================================
    # Audit Query Methods
    #===========================================================================
    
    # Retrieves audit history for a specific permission
    # @param permission [Hub::Admin::Permission] the permission to get history for
    # @param limit [Integer] maximum number of history entries to return
    # @return [Array<Hub::Admin::PermissionAudit>] the audit history
    def self.permission_history(permission, limit = 50)
      Hub::Admin::PermissionAudit
        .for_permission(permission)
        .latest
        .limit(limit)
    end
    
    # Retrieves audit history for a namespace
    # @param namespace [String] the namespace to get history for
    # @param limit [Integer] maximum number of history entries to return
    # @return [Array<Hub::Admin::PermissionAudit>] the audit history
    def self.namespace_history(namespace, limit = 50)
      Hub::Admin::PermissionAudit
        .for_namespace(namespace)
        .latest
        .limit(limit)
    end
    
    # Retrieves audit history for a controller
    # @param namespace [String] the namespace of the controller
    # @param controller [String] the controller to get history for
    # @param limit [Integer] maximum number of history entries to return
    # @return [Array<Hub::Admin::PermissionAudit>] the audit history
    def self.controller_history(namespace, controller, limit = 50)
      Hub::Admin::PermissionAudit
        .for_namespace(namespace)
        .for_controller(controller)
        .latest
        .limit(limit)
    end
    
    # Retrieves recent permission changes across the system
    # @param limit [Integer] maximum number of history entries to return
    # @param change_types [Array<String>] optional filter for specific change types
    # @return [Array<Hub::Admin::PermissionAudit>] the audit history
    def self.recent_changes(limit = 100, change_types = nil)
      query = Hub::Admin::PermissionAudit.latest
      
      # Apply change type filter if specified
      query = query.where(change_type: change_types) if change_types.present?
      
      query.limit(limit)
    end
    
    # Retrieves stats about permission changes
    # @param days [Integer] number of days to look back
    # @return [Hash] statistics about permission changes
    def self.change_statistics(days = 30)
      # Calculate the cutoff date
      cutoff_date = Time.zone.now - days.days
      
      # Get all audit records since the cutoff date
      audits = Hub::Admin::PermissionAudit.where('created_at > ?', cutoff_date)
      
      # Group by change type
      changes_by_type = audits.group(:change_type).count
      
      # Group by user (for top changers)
      changes_by_user = audits.where.not(user_id: nil).group(:user_id).count
      top_changers = changes_by_user.sort_by { |_, count| -count }.take(5).map do |user_id, count|
        user = Hub::Admin::User.find_by(id: user_id)
        { id: user_id, name: user&.full_name || 'Unknown User', count: count }
      end
      
      # Group by day for trend data
      changes_by_day = audits
        .group("DATE(created_at)")
        .count
        .transform_keys { |date| date.to_s }
      
      # Return compiled statistics
      {
        total_changes: audits.count,
        by_type: changes_by_type,
        top_changers: top_changers,
        trend: changes_by_day
      }
    end
  end
end
