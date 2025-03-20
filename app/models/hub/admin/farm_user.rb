# == Schema Information
#
# Table name: hub_core_farm_users
#
#  id         :bigint           not null, primary key
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  farm_id    :bigint           not null
#  user_id    :bigint           not null
#
# Indexes
#
#  idx_farm_users_lookup                 (farm_id,user_id) UNIQUE
#  index_hub_core_farm_users_on_farm_id  (farm_id)
#  index_hub_core_farm_users_on_user_id  (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (farm_id => hub_core_farms.id)
#  fk_rails_...  (user_id => hub_admin_users.id)
#
module Hub
  module Admin
    class FarmUser < ApplicationRecord
      self.table_name = 'hub_admin_farm_users'
      
      # Associations
      belongs_to :farm, class_name: 'Hub::Admin::Farm'
      belongs_to :user, class_name: 'Hub::Admin::User'

      # Validations
      validates :farm_id, uniqueness: { scope: :user_id, message: "User is already associated with this farm" }
    end
  end
end
