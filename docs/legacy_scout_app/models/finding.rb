# == Schema Information
#
# Table name: findings
#
#  id                          :bigint           not null, primary key
#  depth                       :integer          not null
#  finding_averaged_raw_weight :integer
#  finding_net_weight          :integer
#  finding_raw_weight          :integer
#  observation                 :text
#  created_at                  :datetime         not null
#  updated_at                  :datetime         not null
#  dog_id                      :bigint           not null
#  harvester_id                :bigint
#  harvesting_run_id           :bigint
#  location_id                 :bigint           not null
#  surveyor_id                 :bigint           not null
#
# Indexes
#
#  index_findings_on_avg_weight         (finding_averaged_raw_weight)
#  index_findings_on_dog_id             (dog_id)
#  index_findings_on_harvester_id       (harvester_id)
#  index_findings_on_harvesting_run_id  (harvesting_run_id)
#  index_findings_on_location_id        (location_id)
#  index_findings_on_raw_weight         (finding_raw_weight)
#  index_findings_on_surveyor_id        (surveyor_id)
#
# Foreign Keys
#
#  fk_rails_...  (dog_id => dogs.id)
#  fk_rails_...  (harvester_id => users.id)
#  fk_rails_...  (harvesting_run_id => harvesting_runs.id)
#  fk_rails_...  (location_id => locations.id)
#  fk_rails_...  (surveyor_id => users.id)
#
class Finding < ApplicationRecord
  include Seasonable
  include WeeklyStatistics
  belongs_to :dog
  belongs_to :harvester, class_name: 'User'
  belongs_to :surveyor, class_name: 'User'
  belongs_to :harvesting_run, optional: true
  belongs_to :location, optional: false  # explicitly require location

  scope :in_current_season, ->(inoculation_id = nil) { 
    inoculation_id ||= Inoculation.first&.id
    return none unless inoculation_id
    where(created_at: current_season_range(inoculation_id)) 
  }

  scope :total_weight, -> {
    select('COALESCE(SUM(CASE 
      WHEN finding_raw_weight > 0 THEN finding_raw_weight 
      WHEN finding_averaged_raw_weight > 0 THEN finding_averaged_raw_weight 
      ELSE 0 END), 0) as total_weight')
    .take
    .total_weight
  }

  def self.weekly_stats
    begin
      # Create a cache key based on the latest finding update
      cache_key = "finding/weekly_stats/#{maximum(:updated_at).to_i}"
      
      # Try to get from cache first
      Rails.cache.fetch(cache_key, expires_in: 1.hour) do
        result = {}
        
        # Group findings by week
        findings_by_week = group_by_week(:created_at, week_start: :monday)
          .select('DATE_TRUNC(\'week\', findings.created_at) AS week_start')
          .select('COUNT(findings.id) AS count')
          .select('SUM(COALESCE(findings.finding_raw_weight, findings.finding_averaged_raw_weight, 0)) AS total_weight')
          .select('ARRAY_AGG(DISTINCT locations.row_id) AS row_ids')
          .select('ARRAY_AGG(DISTINCT findings.location_id) AS location_ids')
          .joins(location: { row: :parcel })
          .group('week_start')
          .order('week_start DESC')
          
        # Process each week's data
        findings_by_week.each do |weekly_data|
          week_start = weekly_data.week_start.to_date.to_s
          
          # Get the locations checked in this week
          locations_checked = weekly_data.location_ids.uniq.compact.size
          
          # Get parcel IDs for this week's findings
          row_parcels = Row.where(id: weekly_data.row_ids.uniq.compact)
            .pluck(:parcel_id)
            .uniq.compact
            
          # Get findings by parcel for this week
          findings_by_parcel = {}
          if row_parcels.any?
            findings_in_week = where('DATE_TRUNC(\'week\', findings.created_at) = ?', weekly_data.week_start)
              .joins(location: { row: :parcel })
              .select('parcels.id AS parcel_id, findings.id AS finding_id')
              .select('COALESCE(findings.finding_raw_weight, findings.finding_averaged_raw_weight, 0) AS weight')
              
            findings_in_week.each do |finding|
              findings_by_parcel[finding.parcel_id] ||= []
              findings_by_parcel[finding.parcel_id] << {
                id: finding.finding_id,
                weight: finding.weight.to_f
              }
            end
          end
          
          # Store all the week's statistics
          result[week_start] = {
            count: weekly_data.count.to_i,
            total_weight: weekly_data.total_weight.to_f,
            locations_checked: locations_checked,
            parcels: row_parcels,
            findings_by_parcel: findings_by_parcel
          }
        end
        
        result
      end
    rescue => e
      Rails.logger.error("Error generating weekly stats: #{e.message}\n#{e.backtrace.join("\n")}")
      {}
    end
  end

  enum :depth, {
    surface: 0,
    intermediate: 1,
    deep: 2
  }

  validates :depth, presence: { message: 'must be selected' }
  validates :location, presence: { message: 'must be selected' }
  validates :finding_raw_weight, numericality: { only_integer: true, greater_than: 0 }, allow_nil: true
  validates :finding_net_weight, numericality: { only_integer: true, greater_than: 0 }, allow_nil: true
  
  validate :net_weight_less_than_raw_weight
  validate :location_must_exist

  scope :standalone, -> { where(harvesting_run_id: nil) }
  scope :in_runs, -> { where.not(harvesting_run_id: nil) }
  scope :recent, -> { order(created_at: :desc).limit(5) }

  # Callbacks
  after_save :expire_related_caches
  after_destroy :expire_related_caches

  def expire_related_caches
    # Expire caches for the related parcel
    if location&.row&.parcel
      parcel = location.row.parcel
      parcel.expire_caches
      
      # Schedule background job to update statistics
      # Always use perform_later for better performance
      UpdateParcelStatisticsJob.perform_later(parcel.id)
      
      # Also trigger weekly findings refresh
      UpdateParcelWeeklyFindingsJob.perform_later(parcel.id)
    end
  end

  def finding_raw_weight
    self[:finding_raw_weight].presence || finding_averaged_raw_weight
  end

  def default_created_at
    return Time.zone.now unless harvesting_run

    time_difference = ((Time.zone.now - harvesting_run.started_at) / 1.hour).abs
    return Time.zone.now if time_difference <= 3 && !harvesting_run.stopped_at

    # Use the earliest finding time if there are findings, otherwise use run's start time
    harvesting_run.findings.minimum(:created_at) || harvesting_run.started_at
  end

  private

  def net_weight_less_than_raw_weight
    return unless finding_net_weight.present? && finding_raw_weight.present?

    if finding_net_weight > finding_raw_weight
      errors.add(:finding_net_weight, "must be less than raw weight")
    end
  end

  def location_must_exist
    return if location.present?
    errors.add(:location, "must exist")
  end
end
