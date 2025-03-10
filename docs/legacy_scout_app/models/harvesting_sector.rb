# == Schema Information
#
# Table name: harvesting_sectors
#
#  id         :bigint           not null, primary key
#  name       :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  parcel_id  :bigint
#
# Indexes
#
#  index_harvesting_sectors_on_name_and_parcel_id  (name,parcel_id) UNIQUE
#  index_harvesting_sectors_on_parcel_id           (parcel_id)
#
# Foreign Keys
#
#  fk_rails_...  (parcel_id => parcels.id)
#
class HarvestingSector < ApplicationRecord
  include HasActualPlantings

  belongs_to :parcel

  has_many :rows
  has_many :locations, through: :rows
  has_many :plantings, through: :locations
  has_many :harvesting_runs
  
  validates :name, presence: true, uniqueness: true
  validate :name_must_be_canonical_format

  delegate :orchard, to: :parcel
  delegate :farm, to: :orchard

  private

  def name_must_be_canonical_format
    return if name.blank?

    # The name should be a chain of names separated by hyphens
    # and should include the names of farm, orchard, parcel, and sector
    parts = name.split('-')
    
    if parts.length != 4
      errors.add(:name, "must be in canonical format 'farm-orchard-parcel-sector'")
      return
    end

    # Verify each part matches its corresponding parent
    if farm&.name != parts[0]
      errors.add(:name, "must start with the farm name '#{farm&.name}'")
    end

    if orchard&.name != parts[1]
      errors.add(:name, "must include the orchard name '#{orchard&.name}' as second part")
    end

    if parcel&.name != parts[2]
      errors.add(:name, "must include the parcel name '#{parcel&.name}' as third part")
    end
  end
end
