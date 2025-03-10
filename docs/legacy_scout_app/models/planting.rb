# == Schema Information
#
# Table name: plantings
#
#  id             :bigint           not null, primary key
#  planted_at     :date
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  inoculation_id :bigint           not null
#  nursery_id     :bigint           not null
#  species_id     :bigint           not null
#
# Indexes
#
#  index_plantings_on_inoculation_id  (inoculation_id)
#  index_plantings_on_nursery_id      (nursery_id)
#  index_plantings_on_species_id      (species_id)
#
# Foreign Keys
#
#  fk_rails_...  (inoculation_id => inoculations.id)
#  fk_rails_...  (nursery_id => nurseries.id)
#  fk_rails_...  (species_id => species.id)
#
class Planting < ApplicationRecord
  include SpringAgeable
  
  belongs_to :nursery
  belongs_to :inoculation
  belongs_to :species

  has_one :location_planting, dependent: :destroy
  has_one :location, through: :location_planting

  validates :nursery, :inoculation, :species, presence: true
  validates :planted_at, presence: true
  validate :no_duplicate_planted_at, if: :target_location

  delegate :row, :harvesting_sector, :parcel, :orchard, :farm, to: :location, allow_nil: true

  attr_accessor :target_location

  after_create :create_location_planting
  
  # Determine if this planting is an original planting for a specific season
  # Based solely on the planting date relative to the season start
  # @param season_start [Date, Time] The start date of the season to check
  # @return [Boolean] true if this is an original planting for the specified season
  def original_for_season?(season_start)
    return false unless planted_at.present? && inoculation.present?
    
    # Use the Seasonable concern's method to check if this is an original planting
    Finding.is_original_planting_for_season?(inoculation.id, planted_at, season_start)
  end
  
  # Check if this is the first (original) planting at its location
  # @return [Boolean] true if this is the first planting at its location
  def original_at_location?
    return false unless location.present?
    
    # Find the first planting at this location by planted_at date
    original = location.original_planting
    
    # Check if this is the original planting
    original && original.id == id
  end
  
  # Check if this was the active planting at its location at the start of a specific season
  # @param season_start [Date, Time] The start date of the season to check
  # @return [Boolean] true if this was the active planting at the start of the specified season
  def active_at_season_start?(season_start)
    return false unless location.present? && season_start.present?
    
    # Find the active planting at this location at the start of the season
    active_planting = location.actual_planting_at(season_start)
    
    # Check if this is the active planting
    active_planting && active_planting.id == id
  end

  private

  def create_location_planting
    return unless target_location

    LocationPlanting.create!(
      planting: self,
      location: target_location
    )
  end

  def no_duplicate_planted_at
    return unless target_location
    return unless planted_at

    if LocationPlanting.joins(:planting)
                      .where(location: target_location)
                      .where.not(plantings: { id: id })
                      .where(plantings: { planted_at: planted_at })
                      .exists?
      errors.add(:planted_at, "already has a planting on this date")
    end
  end
end
