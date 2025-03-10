# == Schema Information
#
# Table name: rows
#
#  id                   :bigint           not null, primary key
#  locations_count      :integer          default(0), not null
#  name                 :string
#  rank                 :integer          not null
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  harvesting_sector_id :bigint
#  parcel_id            :bigint           not null
#
# Indexes
#
#  index_rows_on_harvesting_sector_id  (harvesting_sector_id)
#  index_rows_on_locations_count       (locations_count)
#  index_rows_on_name_and_parcel_id    (name,parcel_id) UNIQUE
#  index_rows_on_parcel_id             (parcel_id)
#
# Foreign Keys
#
#  fk_rails_...  (harvesting_sector_id => harvesting_sectors.id)
#  fk_rails_...  (parcel_id => parcels.id)
#
class Row < ApplicationRecord
  include HasActualPlantings
  include CanonicalNaming

  belongs_to :parcel, counter_cache: :locations_count
  belongs_to :harvesting_sector

  has_many :locations, dependent: :destroy do
    def create_with_counter_update!(attributes = {})
      location = create!(attributes)
      proxy_association.owner.parcel.increment!(:locations_count)
      location
    end
  end
  has_many :plantings, through: :locations
  
  validates :name, presence: true, uniqueness: { scope: :parcel_id }
  validates :rank, presence: true, numericality: { only_integer: true }

  delegate :orchard, to: :parcel
  delegate :farm, to: :orchard
end
