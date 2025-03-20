# == Schema Information
#
# Table name: hub_core_farms
#
#  id          :bigint           not null, primary key
#  active      :boolean          default(TRUE), not null
#  address     :text
#  description :text
#  handle      :string           not null
#  logo        :string
#  name        :string           not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
# Indexes
#
#  index_hub_core_farms_on_handle  (handle) UNIQUE
#  index_hub_core_farms_on_name    (name)
#
module Hub
  module Admin
    class Farm < ApplicationRecord
      self.table_name = 'hub_admin_farms'
      
      # Associations
      has_many :farm_users, dependent: :destroy
      has_many :users, through: :farm_users, class_name: 'Hub::Admin::User'
      has_one_attached :logo
      
      # Validations
      validates :name, presence: true
      validates :handle, presence: true, uniqueness: { case_sensitive: false }
      
      # Normalizes
      normalizes :name, :handle, with: ->(value) { value.to_s.strip.presence }
      normalizes :handle, with: ->(handle) { handle.to_s.downcase.gsub(/\s+/, '-') }
      
      # Scopes
      scope :active, -> { where(active: true) }
      
      # Methods
      def active?
        active
      end
      
      # Attach farm to user
      def add_user(user)
        # Create or find the farm user association
        farm_users.find_or_create_by(user: user)
      end
    end
  end
end
