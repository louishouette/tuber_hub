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
      scope :ordered, -> { order(:name) }
      
      # Methods
      def active?
        true  # Roles are always active unless explicitly deleted
      end
      
      def to_s
        name
      end
    end
  end
end
