# == Schema Information
#
# Table name: parcels
#
#  id                         :bigint           not null, primary key
#  findings_count             :integer          default(0), not null
#  locations_count            :integer          default(0), not null
#  name                       :string
#  planted_at                 :date
#  plantings_count            :integer          default(0), not null
#  weekly_findings_data       :jsonb
#  weekly_findings_updated_at :datetime
#  created_at                 :datetime         not null
#  updated_at                 :datetime         not null
#  orchard_id                 :bigint           not null
#
# Indexes
#
#  index_parcels_on_findings_count              (findings_count)
#  index_parcels_on_locations_count             (locations_count)
#  index_parcels_on_name                        (name)
#  index_parcels_on_name_and_orchard_id         (name,orchard_id) UNIQUE
#  index_parcels_on_orchard_id                  (orchard_id)
#  index_parcels_on_planted_at                  (planted_at)
#  index_parcels_on_plantings_count             (plantings_count)
#  index_parcels_on_weekly_findings_updated_at  (weekly_findings_updated_at)
#
# Foreign Keys
#
#  fk_rails_...  (orchard_id => orchards.id)
#
class Parcel < ApplicationRecord
  include Seasonable
  include SpringAgeable
  include WeekFormattable
  include HasTimingStats
  include CanonicalNaming
  
  belongs_to :orchard
  
  has_many :harvesting_sectors
  has_many :rows, dependent: :destroy
  has_many :locations, through: :rows
  has_many :plantings, through: :locations
  has_many :findings, through: :locations
  has_many :harvesting_runs, through: :findings

  validates :name, presence: true, uniqueness: { scope: :orchard_id }

  delegate :farm, to: :orchard
  
  # Add database column for spring_age to make filtering more efficient
  def calculate_spring_age
    spring_age
  end

  # Counter cache columns - leveraged for performance
  scope :with_locations_count, -> { select('parcels.*, parcels.locations_count as cached_locations_count') }
  scope :with_plantings_count, -> { select('parcels.*, parcels.plantings_count as cached_plantings_count') }
  scope :with_findings_count, -> { select('parcels.*, parcels.findings_count as cached_findings_count') }
  
  # Optimized scope for species filtering - replaces complex joins in controller
  scope :with_species, ->(species_id) {
    joins(rows: { locations: { location_plantings: { planting: :species } } })
    .where(species: { id: species_id })
    .distinct
  }

  # Optimized scope for basic topology data - reduced to minimize DB load
  scope :with_basic_topology, -> {
    includes(:orchard, rows: :locations)
  }

  # Scope for advanced topology with deeply nested associations - only use when needed
  scope :with_full_topology_data, -> {
    includes(
      :orchard,
      rows: {
        locations: [
          :findings,
          { location_plantings: { planting: [:species, :inoculation, :nursery] } }
        ]
      }
    )
  }

  scope :with_findings_in_date_range, ->(start_date, end_date) {
    joins(rows: { locations: :findings })
      .where(findings: { created_at: start_date..end_date })
      .distinct
  }

  # Scope to get parcels with their species statistics
  scope :with_species_stats, -> {
    left_joins(rows: { locations: [
      :findings,
      { location_plantings: { planting: :species } }
    ]})
    .select('parcels.*, species.id as species_id, species.name as species_name')
    .select('COUNT(DISTINCT location_plantings.id) as planting_count')
    .select('COUNT(DISTINCT findings.id) as findings_count')
    .select('SUM(COALESCE(findings.finding_raw_weight, findings.finding_averaged_raw_weight, 0)) as total_weight')
    .group('parcels.id, species.id, species.name')
  }

  # Scope to get parcels with their replacement statistics
  scope :with_replacement_stats, -> {
    left_joins(rows: { locations: :location_plantings })
    .select('parcels.*')
    .select('COUNT(DISTINCT locations.id) as total_locations_count')
    .select('COUNT(DISTINCT CASE WHEN (
      SELECT COUNT(*) FROM location_plantings lp 
      WHERE lp.location_id = locations.id
    ) > 1 THEN locations.id END) as replaced_locations_count')
    .group('parcels.id')
  }

  # Scope to get parcels with their findings distribution
  scope :with_findings_distribution, -> {
    left_joins(rows: { locations: :findings })
    .select('parcels.*')
    .select('COUNT(DISTINCT locations.id) as total_locations_count')
    .select('COUNT(DISTINCT CASE WHEN findings.id IS NULL THEN locations.id END) as no_findings_count')
    .select('COUNT(DISTINCT CASE WHEN (
      SELECT COUNT(*) FROM findings f 
      WHERE f.location_id = locations.id
    ) = 1 THEN locations.id END) as one_finding_count')
    .select('COUNT(DISTINCT CASE WHEN (
      SELECT COUNT(*) FROM findings f 
      WHERE f.location_id = locations.id
    ) = 2 THEN locations.id END) as two_findings_count')
    .select('COUNT(DISTINCT CASE WHEN (
      SELECT COUNT(*) FROM findings f 
      WHERE f.location_id = locations.id
    ) = 3 THEN locations.id END) as three_findings_count')
    .select('COUNT(DISTINCT CASE WHEN (
      SELECT COUNT(*) FROM findings f 
      WHERE f.location_id = locations.id
    ) >= 4 THEN locations.id END) as four_plus_findings_count')
    .group('parcels.id')
  }

  # Scopes for filtering
  # The with_spring_age scope is provided by SpringAgeable concern
  
  # Optimized scope for species filtering
  scope :with_species, ->(species_ids) {
    joins(rows: { locations: { location_plantings: { planting: :species } } })
    .where(species: { id: species_ids })
    .distinct
  }
  
  # Optimized scope for inoculation filtering
  scope :with_inoculation, ->(inoculation_id) {
    joins(rows: { locations: { location_plantings: { planting: :inoculation } } })
    .where(inoculations: { id: inoculation_id })
    .distinct
  }
  
  # Spring age functionality is provided by SpringAgeable concern
  include SpringAgeable

  # Callback to expire caches when a parcel is updated
  after_save :expire_caches
  after_destroy :expire_caches
  
  # Callback to trigger statistics update
  after_save :schedule_statistics_update, if: :saved_change_to_planted_at?
  
  # Handle finding changes through model callbacks
  def self.update_stats_for_locations(location_ids)
    return if location_ids.blank?
    
    # Find all parcels that have these locations
    parcel_ids = Location.where(id: location_ids)
                        .joins(:row)
                        .pluck('rows.parcel_id')
                        .uniq
                        
    # Schedule background jobs for these parcels
    parcel_ids.each do |parcel_id|
      UpdateParcelStatisticsJob.perform_later(parcel_id)
      UpdateParcelWeeklyFindingsJob.perform_later(parcel_id)
    end
  end
  
  # Method to quickly enqueue a statistics update job
  def schedule_statistics_update
    UpdateParcelStatisticsJob.perform_later(id)
  end

  def expire_caches
    Rails.cache.delete("parcel/#{id}/statistics")
    Rails.cache.delete("parcel/#{id}/production_stats")
    Rails.cache.delete("parcel/#{id}/findings_distribution")
    Rails.cache.delete("parcel/#{id}/species_stats")
  end

  def timing_stats_joins
    { findings: :location }
  end

  # Weekly findings data stored in JSON
  def weekly_findings
    return weekly_findings_data if weekly_findings_data.present?
    UpdateParcelWeeklyFindingsJob.perform_later([id]) if weekly_findings_updated_at.nil? || weekly_findings_updated_at < 2.days.ago
    {}
  end

  # Enhanced method to retrieve cached statistics or calculate them if necessary
  def get_statistics
    # Check if we have a recent enough cache first
    cache_key = "parcel/#{id}/statistics"
    
    stats = Rails.cache.fetch(cache_key, expires_in: 10.minutes) do
      # If cache miss, schedule a background job for future requests
      UpdateParcelStatisticsJob.perform_later(id)
      
      # Return basic stats while waiting for the job to complete
      # This ensures the page loads quickly even if full stats calculation takes time
      {
        parcel: self,
        total_locations: locations_count || 0,
        total_plantings: plantings_count || 0,
        findings_count: findings_count || 0,
        # Use cached values if available, or defaults if not
        production_stats: cached_production_stats || { 
          total: "0g", 
          per_location: "0g", 
          per_planting: "0g", 
          per_producing_planting: "0g" 
        },
        findings_distribution: cached_findings_distribution || {
          no_findings: 0,
          one_finding: 0,
          two_findings: 0,
          three_findings: 0,
          four_plus_findings: 0,
          replacements: 0
        },
        species_stats: cached_species_stats || [],
        replacement_ratio: 0
      }
    end
    
    stats
  end
  
  # Helper methods to get cached individual statistics
  def cached_production_stats
    Rails.cache.fetch("parcel/#{id}/production_stats", expires_in: 1.hour) do
      ::ProductionStatsService.calculate(self)
    end
  end
  
  def cached_findings_distribution
    Rails.cache.fetch("parcel/#{id}/findings_distribution", expires_in: 1.hour) do
      ::FindingsDistributionService.calculate(self)
    end
  end
  
  def cached_species_stats
    Rails.cache.fetch("parcel/#{id}/species_stats", expires_in: 1.hour) do
      ::SpeciesStatsService.calculate(self)
    end
  end

  # Enhanced method to retrieve comprehensive statistics for the simplified parcel card
  def get_enhanced_statistics(season: 'current')
    # Check if we have a recent enough cache first
    cache_key = "parcel/#{id}/enhanced_statistics/#{season}"
    
    stats = Rails.cache.fetch(cache_key, expires_in: 10.minutes) do
      # Get inoculation from the first planting for this parcel
      first_planting = plantings.order(planted_at: :asc).first
      inoculation = first_planting&.inoculation
      
      # Get current and previous season date ranges
      current_season_range = if inoculation
        start_date = Finding.current_season_start(inoculation.id)
        end_date = Finding.current_season_end(inoculation.id)
        start_date..end_date
      else
        # Default to a year if no inoculation found
        1.year.ago..Time.zone.now
      end
      
      previous_season_range = if inoculation
        previous_start = Finding.previous_season_start(inoculation.id)
        previous_end = Finding.previous_season_end(inoculation.id)
        previous_start..previous_end
      else
        # Default to previous year if no inoculation found
        2.years.ago..1.year.ago
      end
      
      # Calculate season display string
      season_display = calculate_season_display
      
      # Calculate species distribution
      species_distribution = calculate_species_distribution
      
      # Get planting distribution statistics
      planting_distribution = calculate_planting_distribution
      
      # Get species-specific replacements
      species_replacements_data = calculate_species_replacements
      
      # Calculate total locations and replacement ratio
      total_locations = Location.joins(row: :parcel)
                               .where(rows: { parcel_id: id })
                               .count
      
      total_location_plantings = LocationPlanting.joins(location: { row: :parcel })
                                               .where(locations: { rows: { parcel_id: id } })
                                               .count
      
      # Count locations that have more than one planting (used for 'Remplacements' column)
      locations_with_multiple_plantings = Location.joins(row: :parcel)
                                                .where(rows: { parcel_id: id })
                                                .joins(:location_plantings)
                                                .group('locations.id')
                                                .having('COUNT(location_plantings.id) > 1')
                                                .count
                                                .count # Count the hash entries
      
      replacement_count = total_location_plantings - total_locations
      replacement_ratio = total_locations > 0 ? (replacement_count.to_f / total_locations) : 0.0
      
      # Current season stats
      current_season_findings = findings.where(created_at: current_season_range)
      current_findings_count = current_season_findings.count
      current_total_weight = current_season_findings.sum('COALESCE(findings.finding_raw_weight, findings.finding_averaged_raw_weight, 0)').to_f
      current_avg_weight = current_findings_count > 0 ? (current_total_weight / current_findings_count) : 0.0
      
      # Locations with findings in current season (producers)
      current_producers = locations.joins(:findings)
                                  .where(findings: { created_at: current_season_range })
                                  .distinct
                                  .count
      
      current_producer_ratio = total_locations > 0 ? (current_producers.to_f / total_locations) : 0.0
      
      # Production per planting in current season
      current_production_per_planting = total_locations > 0 ? (current_total_weight / total_locations) : 0.0
      
      # Previous season stats for comparison
      previous_season_findings = findings.where(created_at: previous_season_range)
      previous_findings_count = previous_season_findings.count
      previous_total_weight = previous_season_findings.sum('COALESCE(findings.finding_raw_weight, findings.finding_averaged_raw_weight, 0)').to_f
      previous_avg_weight = previous_findings_count > 0 ? (previous_total_weight / previous_findings_count) : 0.0
      
      # Previous producers
      previous_producers = locations.joins(:findings)
                                   .where(findings: { created_at: previous_season_range })
                                   .distinct
                                   .count
      
      previous_producer_ratio = total_locations > 0 ? (previous_producers.to_f / total_locations) : 0.0
      
      # Previous production per planting
      previous_production_per_planting = total_locations > 0 ? (previous_total_weight / total_locations) : 0.0
      
      # Calculate g/Producing Planting for both seasons
      # Note: total_weight is already in grams, no need to multiply by 1000
      current_g_per_producing = current_producers > 0 ? (current_total_weight / current_producers) : 0.0
      previous_g_per_producing = previous_producers > 0 ? (previous_total_weight / previous_producers) : 0.0

      # Calculate percentage changes for comparison
      findings_count_change = calculate_percentage_change(previous_findings_count, current_findings_count)
      total_weight_change = calculate_percentage_change(previous_total_weight, current_total_weight)
      avg_weight_change = calculate_percentage_change(previous_avg_weight, current_avg_weight)
      producers_change = calculate_percentage_change(previous_producers, current_producers)
      producer_ratio_change = calculate_percentage_change(previous_producer_ratio, current_producer_ratio)
      production_per_planting_change = calculate_percentage_change(previous_production_per_planting, current_production_per_planting)
      g_per_producing_change = calculate_percentage_change(previous_g_per_producing, current_g_per_producing)
      
      # Return the enhanced statistics
      {
        # Always include the parcel object itself
        parcel: self,
        id: id,
        name: name,
        total_locations: total_locations,
        total_plantings: plantings_count || 0,
        findings_count: findings_count || 0,
        replacement_count: replacement_count,
        replacement_ratio: replacement_ratio,
        locations_with_multiple_plantings: locations_with_multiple_plantings,
        planting_distribution: planting_distribution,
        original_plantings_count: planting_distribution[:original_plantings],
        total_replacements_count: planting_distribution[:total_replacements],
        actual_replacements_count: planting_distribution[:actual_replacements],
        species_replacements_data: species_replacements_data,
        inoculation: inoculation,
        spring_age: spring_age || 0,
        season_display: season_display,
        species_distribution: species_distribution,
        current_season: {
          findings_count: current_findings_count,
          total_weight: current_total_weight,
          average_weight: current_avg_weight,
          producers_count: current_producers,
          producer_ratio: current_producer_ratio,
          production_per_planting: current_production_per_planting,
          g_per_producing: current_g_per_producing
        },
        previous_season: {
          findings_count: previous_findings_count,
          total_weight: previous_total_weight,
          average_weight: previous_avg_weight,
          producers_count: previous_producers,
          producer_ratio: previous_producer_ratio,
          production_per_planting: previous_production_per_planting,
          g_per_producing: previous_g_per_producing
        },
        changes: {
          findings_count: findings_count_change,
          total_weight: total_weight_change,
          average_weight: avg_weight_change,
          producers_count: producers_change,
          producer_ratio: producer_ratio_change,
          production_per_planting: production_per_planting_change,
          g_per_producing: g_per_producing_change
        }
      }
    end
    
    stats
  end
  
  # Helper method to calculate percentage change between two values
  def calculate_percentage_change(previous, current)
    # Return nil if we have no previous data to compare against
    return nil if previous.nil? || previous.zero?
    return nil if current.nil?
    
    ((current - previous) / previous.to_f * 100).round
  end
  
  # Helper method to calculate species distribution
  def calculate_species_distribution
    # Group plantings by species and calculate percentages
    species_counts = LocationPlanting.joins(location: { row: :parcel }, planting: :species)
                                    .where(locations: { rows: { parcel_id: id } })
                                    .group('species.id', 'species.name')
                                    .count
    
    total_count = species_counts.values.sum
    return [] if total_count.zero?
    
    # Transform to array of hashes with species info and percentage
    species_list = species_counts.map do |(species_id, species_name), count|
      {
        id: species_id,
        name: species_name,
        count: count,
        percentage: ((count.to_f / total_count) * 100).round
      }
    end.sort_by { |s| -s[:percentage] }
    
    # Return all species without limiting
    species_list
  end

  def compute_and_store_weekly_findings
    # Get the first inoculation ID (for determining season)
    inoculation_id = Inoculation.first&.id
    return {} unless inoculation_id
    
    findings_by_week = findings.in_current_season(inoculation_id)
                               .select('DATE_TRUNC(\'week\', findings.created_at) as week, SUM(COALESCE(findings.finding_raw_weight, findings.finding_averaged_raw_weight, 0)) as total_weight')
                               .group('DATE_TRUNC(\'week\', findings.created_at)')
                               .order('week')
                               .each_with_object({}) do |result, hash|
                                 hash[result.week.to_date] = result.total_weight.to_f
                               end  

    # Get all weeks in chronological order
    season_start = Finding.current_season_start(inoculation_id).to_date
    season_end = Finding.current_season_end(inoculation_id).to_date
    all_weeks = (season_start..season_end).step(7).map do |date|
      week_start = date.beginning_of_week(:monday)
      [week_start, format_week(week_start)]
    end  

    # Create array of [week, value] pairs to maintain order
    data_array = all_weeks.map do |week_start, formatted_week|
      [formatted_week.to_s, findings_by_week[week_start.to_date].to_f || 0.0]
    end

    # Convert to hash while maintaining order
    data = data_array.to_h  

    # Store the array format to maintain order
    result = update_columns(
      weekly_findings_data: data_array,
      weekly_findings_updated_at: Time.zone.now
    )  
    
    # Clear cache of this specific parcel
    expire_caches
    
    # Return the data
    data_array
  end
  
  def update_planted_at
    self.planted_at ||= begin
      # Try to infer planted_at from the earliest planting date
      earliest_planting = plantings.order(planted_at: :asc).first
      earliest_planting&.planted_at || Time.zone.now
    end
  end
  
  # Calculate current season display string (e.g., "2024-2025")
  def calculate_season_display
    # Get inoculation from the first planting for this parcel
    first_planting = plantings.order(planted_at: :asc).first
    inoculation = first_planting&.inoculation
    
    if inoculation.present?
      # Try to use Seasonable concern if available
      begin
        if Season.respond_to?(:current_season_range)
          current_season_range = Season.current_season_range(inoculation.id)
          season_start = current_season_range.begin
          season_end = current_season_range.end
          return "#{season_start.year} - #{season_end.year}"
        end
      rescue
        # Continue with fallback if there's an error
      end
    end
    
    # Default calculation if no inoculation or if Seasonable not available
    current_date = Time.zone.now
    if current_date.month >= 7
      "#{current_date.year} - #{current_date.year + 1}"
    else
      "#{current_date.year - 1} - #{current_date.year}"
    end
  end
  
  # Calculate the distribution of plantings per location
  def calculate_planting_distribution
    # Get the distribution of plantings per location
    location_planting_counts = Location.joins(row: :parcel)
                                      .where(rows: { parcel_id: id })
                                      .joins(:plantings)
                                      .group('locations.id')
                                      .count('plantings.id')
                                      .group_by { |_, count| count }
                                      .transform_values(&:count)
    
    # Calculate original plantings (locations with exactly 1 planting)
    original_plantings_count = location_planting_counts[1] || 0
    
    # Calculate total replacements (sum of all plantings beyond the first one)
    total_replacements_count = 0
    location_planting_counts.each do |plantings_count, locations_count|
      if plantings_count > 1
        total_replacements_count += (plantings_count - 1) * locations_count
      end
    end
    
    # Calculate actual replacements (locations with more than 1 planting)
    actual_replacements_count = 0
    location_planting_counts.each do |plantings_count, locations_count|
      if plantings_count > 1
        actual_replacements_count += locations_count
      end
    end
    
    # Return a hash with all computed values
    {
      distribution: location_planting_counts,
      original_plantings: original_plantings_count,
      total_replacements: total_replacements_count,
      actual_replacements: actual_replacements_count
    }
  end
  
  # Calculate species-specific replacements for all species in the parcel
  def calculate_species_replacements
    # Get all species used in this parcel
    species_list = Species.joins(plantings: { location_planting: { location: { row: :parcel } }})
                         .where(rows: { parcel_id: id })
                         .distinct
    
    # Calculate replacements for each species
    species_replacements = {}
    
    species_list.each do |species|
      # Get locations with this species
      species_location_count = Location.joins(row: :parcel)
                                     .where(rows: { parcel_id: id })
                                     .joins(location_plantings: { planting: :species })
                                     .where(species: { id: species.id })
                                     .distinct
                                     .count
      
      # Get total plantings for this species
      species_plantings_count = Planting.joins(location_planting: { location: { row: :parcel } })
                                      .where(rows: { parcel_id: id })
                                      .where(species_id: species.id)
                                      .count
      
      # Calculate replacements
      replacements = [species_plantings_count - species_location_count, 0].max
      
      # Store in hash
      species_replacements[species.id] = {
        id: species.id,
        name: species.name,
        color_code: species.color_code,
        location_count: species_location_count,
        plantings_count: species_plantings_count,
        replacements: replacements
      }
    end
    
    species_replacements
  end
end
