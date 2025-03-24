# frozen_string_literal: true

# == Schema Information
#
# Table name: hub_admin_authorization_audits
#
#  id                :bigint           not null, primary key
#  controller_action :string           not null
#  ip_address        :string
#  policy_name       :string           not null
#  query             :string           not null
#  user_agent        :text
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  farm_id           :bigint
#  user_id           :bigint
#
# Indexes
#
#  index_hub_admin_authorization_audits_on_controller_action  (controller_action)
#  index_hub_admin_authorization_audits_on_created_at         (created_at)
#  index_hub_admin_authorization_audits_on_farm_id            (farm_id)
#  index_hub_admin_authorization_audits_on_policy_name        (policy_name)
#  index_hub_admin_authorization_audits_on_user_id            (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (farm_id => hub_admin_farms.id)
#  fk_rails_...  (user_id => hub_admin_users.id)
#
module Hub
  module Admin
    # Tracks authorization failures for security and debugging purposes
    class AuthorizationAudit < ApplicationRecord
      # Associations
      belongs_to :user, class_name: 'Hub::Admin::User', optional: true
      belongs_to :farm, class_name: 'Hub::Admin::Farm', optional: true

      # Validations
      validates :policy_name, :query, :controller_action, presence: true
      
      # Scopes
      scope :recent, -> { order(created_at: :desc) }
      scope :for_user, ->(user_id) { where(user_id: user_id) }
      scope :for_farm, ->(farm_id) { where(farm_id: farm_id) }
      scope :with_policy, ->(policy_name) { where(policy_name: policy_name) }
      
      # Statistics and reporting methods
      
      # Get authorization failures by day for the specified time period
      # @param days [Integer] number of days to look back
      # @return [Hash] counts grouped by day
      def self.failures_by_day(days = 30)
        where('created_at >= ?', days.days.ago)
          .group_by_day(:created_at, week_start: :monday)
          .count
      end
      
      # Get counts of failures grouped by policy
      # @param limit [Integer] maximum number of policies to return
      # @return [Hash] counts grouped by policy
      def self.failures_by_policy(limit = 10)
        group(:policy_name)
          .order('count_all DESC')
          .limit(limit)
          .count
      end
      
      # Get counts of failures grouped by controller action
      # @param limit [Integer] maximum number of controller actions to return
      # @return [Hash] counts grouped by controller action
      def self.failures_by_controller_action(limit = 10)
        group(:controller_action)
          .order('count_all DESC')
          .limit(limit)
          .count
      end
      
      # Get counts of failures grouped by user
      # @param limit [Integer] maximum number of users to return
      # @return [Array<Hash>] user details with failure counts
      def self.failures_by_user(limit = 10)
        user_counts = where.not(user_id: nil)
          .group(:user_id)
          .order('count_all DESC')
          .limit(limit)
          .count
        
        user_ids = user_counts.keys
        users = Hub::Admin::User.where(id: user_ids).index_by(&:id)
        
        user_counts.map do |user_id, count|
          user = users[user_id]
          {
            user_id: user_id,
            email: user&.email || 'Unknown user',
            count: count
          }
        end
      end
    end
  end
end
