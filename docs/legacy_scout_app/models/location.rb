# == Schema Information
#
# Table name: locations
#
#  id                       :bigint           not null, primary key
#  comment                  :text
#  findings_count           :integer          default(0), not null
#  location_plantings_count :integer          default(0), not null
#  name                     :string           not null
#  position                 :integer
#  created_at               :datetime         not null
#  updated_at               :datetime         not null
#  row_id                   :bigint
#
# Indexes
#
#  index_locations_on_findings_count            (findings_count)
#  index_locations_on_location_plantings_count  (location_plantings_count)
#  index_locations_on_name                      (name) UNIQUE
#  index_locations_on_row_id                    (row_id)
#
# Foreign Keys
#
#  fk_rails_...  (row_id => rows.id)
#
class Location < ApplicationRecord

  
  scope :search_by_name, ->(query) {
    # Convert the query into a pattern that matches characters in sequence
    # e.g., 'e21551' becomes 'e.*2.*1.*5.*5.*1'
    pattern = query.chars.join('.*')
    where("REPLACE(locations.name, '-', '') ~* ?", pattern)
      .joins(row: { parcel: { orchard: :farm }})
      .order(Arel.sql('LENGTH(locations.name) ASC, '\
                      'farms.name ASC, '\
                      'orchards.name ASC, '\
                      'parcels.name ASC, '\
                      'rows.name ASC, '\
                      'locations.position ASC'))
  }
  belongs_to :row, counter_cache: true

  has_many :location_plantings, dependent: :destroy, counter_cache: true do
    def create_with_counter_update!(attributes = {})
      planting = create!(attributes)
      proxy_association.owner.row.parcel.increment!(:plantings_count)
      planting
    end
  end
  has_many :plantings, through: :location_plantings
  has_many :findings, dependent: :destroy, counter_cache: true do
    def create_with_counter_update!(attributes = {})
      finding = create!(attributes)
      proxy_association.owner.row.parcel.increment!(:findings_count)
      finding
    end
  end
  
  validates :name, presence: true, uniqueness: true
  validates :row_id, presence: true
  
  delegate :parcel, :harvesting_sector, to: :row
  delegate :orchard, to: :parcel
  delegate :farm, to: :orchard
  
  def qr_code
    name
  end
  
  # Get the most recent planting (the one that is currently alive)
  # @return [Planting, nil] The most recent planting or nil if none exists
  def actual_planting
    plantings.order(planted_at: :desc).first
  end
  
  # Get the planting that was active at a specific date
  # This finds the most recent planting that was planted before or on the specified date
  # @param date [Date, Time] The date to check for
  # @return [Planting, nil] The planting that was active at the specified date or nil if none exists
  def actual_planting_at(date)
    return nil unless date.present?
    
    # Convert date to Time in the current time zone for consistent comparison
    reference_date = date.is_a?(Time) ? date : date.to_time.in_time_zone
    
    # Find the most recent planting that was planted before or on the reference date
    plantings.where('planted_at <= ?', reference_date).order(planted_at: :desc).first
  end
  
  # Get the original (first) planting for this location
  # @return [Planting, nil] The first planting at this location or nil if none exists
  def original_planting
    plantings.order(planted_at: :asc).first
  end

  def self.search(query)
    return all if query.blank?
    clean_query = query.gsub('-', '')
    search_by_name(clean_query)
  end
end
