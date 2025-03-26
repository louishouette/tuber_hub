# frozen_string_literal: true

# == Schema Information
#
# Table name: hub_admin_user_preferences
#
#  id         :bigint           not null, primary key
#  key        :string           not null
#  value      :text
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  user_id    :bigint           not null
#
# Indexes
#
#  index_hub_admin_user_preferences_on_user_id  (user_id)
#  index_user_preferences_on_user_id_and_key    (user_id,key) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (user_id => hub_admin_users.id)
#
module Hub
  module Admin
    # Model for storing user preferences as key-value pairs
    class UserPreference < ApplicationRecord
      # Associations
      belongs_to :user, class_name: 'Hub::Admin::User'

      # Validations
      validates :key, presence: true, uniqueness: { scope: :user_id }
      validates :value, presence: true
      validate :validate_value_format, if: -> { TYPED_PREFERENCES.key?(key) }

      # Scopes
      scope :by_key, ->(key) { where(key: key) }
      scope :system_preferences, -> { where("key LIKE ?", "system_%") }
      scope :user_defined, -> { where("key NOT LIKE ?", "system_%") }

      # Serialize value as JSON - Rails 8 compatible
      serialize :value, coder: JSON

      # Common preference types and their expected data types
      TYPED_PREFERENCES = {
        'default_farm_id' => :integer,
        'theme' => :string,
        'dashboard_layout' => :hash,
        'notifications_enabled' => :boolean,
        'items_per_page' => :integer
      }.freeze

      # Updates the value of a preference with logging
      # @param new_value [Object] The new value to store
      # @return [Boolean] True if the update was successful
      def update_value(new_value)
        Rails.logger.info("Updating user preference: user_id=#{user_id}, key=#{key}, old_value=#{value}, new_value=#{new_value}")
        
        begin
          update(value: new_value)
        rescue => e
          Rails.logger.error("Failed to update user preference: user_id=#{user_id}, key=#{key}, error=#{e.message}")
          false
        end
      end

      # Get a human-readable description of the preference
      # @return [String] A human-readable description
      def description
        case key
        when 'default_farm_id'
          farm = Hub::Admin::Farm.find_by(id: value)
          farm ? "Default farm: #{farm.name}" : "Default farm (not found)"
        when 'theme'
          "UI Theme: #{value.to_s.humanize}"
        when 'dashboard_layout'
          "Custom dashboard layout"
        when 'notifications_enabled'
          value ? "Notifications: Enabled" : "Notifications: Disabled"
        when 'items_per_page'
          "Display #{value} items per page"
        else
          key.humanize
        end
      end

      # Check if this is a system preference (prefixed with 'system_')
      # @return [Boolean] Whether this is a system preference
      def system_preference?
        key.start_with?('system_')
      end

      private

      # Validate that the value matches the expected type for known preference keys
      def validate_value_format
        return unless TYPED_PREFERENCES.key?(key)
        
        expected_type = TYPED_PREFERENCES[key]
        case expected_type
        when :integer
          unless value.is_a?(Integer) || (value.is_a?(String) && value.match?(/\A\d+\z/))
            errors.add(:value, "must be an integer for #{key}")
          end
        when :boolean
          unless [true, false].include?(value) || ['true', 'false'].include?(value.to_s.downcase)
            errors.add(:value, "must be a boolean for #{key}")
          end
        when :string
          errors.add(:value, "must be a string for #{key}") unless value.is_a?(String)
        when :hash
          errors.add(:value, "must be a hash for #{key}") unless value.is_a?(Hash)
        end
      end
    end
  end
end
