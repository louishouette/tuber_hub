# == Schema Information
#
# Table name: location_plantings
#
#  id          :bigint           not null, primary key
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  location_id :bigint           not null
#  planting_id :bigint           not null
#
# Indexes
#
#  index_location_plantings_on_location_id  (location_id)
#  index_location_plantings_on_planting_id  (planting_id)
#
# Foreign Keys
#
#  fk_rails_...  (location_id => locations.id)
#  fk_rails_...  (planting_id => plantings.id)
#
class LocationPlanting < ApplicationRecord
  belongs_to :location
  belongs_to :planting

  # Scopes
  scope :by_planting_date, -> { joins(:planting).order('plantings.planted_at DESC') }

  # Callbacks
  after_save :expire_related_caches
  after_destroy :expire_related_caches

  def expire_related_caches
    # Expire caches for the related parcel
    if location&.row&.parcel
      parcel = location.row.parcel
      parcel.expire_caches
    end
  end
end
