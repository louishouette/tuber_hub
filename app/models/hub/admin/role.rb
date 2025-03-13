# == Schema Information
#
# Table name: hub_admin_roles
#
#  id          :bigint           not null, primary key
#  description :text
#  name        :string
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
module Hub
  module Admin
    class Role < ApplicationRecord
      # Associations
      has_many :role_assignments, dependent: :destroy
      has_many :users, through: :role_assignments
      
      has_many :permission_assignments, dependent: :destroy
      has_many :permissions, through: :permission_assignments
      
      # Validations
      validates :name, presence: true, uniqueness: { case_sensitive: false }
      
      # Scopes
      scope :active, -> { where("expires_at IS NULL OR expires_at > ?", Time.zone.now) }
      
      # Methods
      def expired?
        expires_at.present? && expires_at <= Time.zone.now
      end
      
      def active?
        !expired?
      end
    end
  end
end
