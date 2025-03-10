# == Schema Information
#
# Table name: orchards
#
#  id         :bigint           not null, primary key
#  name       :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  farm_id    :bigint           not null
#
# Indexes
#
#  index_orchards_on_farm_id           (farm_id)
#  index_orchards_on_name_and_farm_id  (name,farm_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (farm_id => farms.id)
#
class Orchard < ApplicationRecord
  include HasActualPlantings
  include CanonicalNaming

  belongs_to :farm

  has_many :parcels
  has_many :harvesting_sectors, through: :parcels
  has_many :rows, through: :parcels
  has_many :locations, through: :rows
  has_many :plantings, through: :locations
  has_many :findings, through: :locations
  
  validates :name, presence: true, uniqueness: { scope: :farm_id }

  scope :with_findings_in_season, ->(season_start, season_end) {
    # Get all locations with findings in the specified season
  }
end
