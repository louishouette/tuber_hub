class ParcelStatisticsService
  def self.calculate(parcel)
    begin
      # Calculate cache expiry time based on season
      cache_duration = in_peak_season? ? 6.hours : 12.hours
      
      # Calculate and cache all statistics efficiently
      Rails.cache.fetch("parcel_stats_full/#{parcel.id}/#{parcel.updated_at.to_i}", expires_in: cache_duration) do
        # Get basic stats
        basic_stats = {
          total_locations: parcel.locations_count || 0,
          total_plantings: parcel.plantings_count || 0,
          findings_count: parcel.findings_count || 0
        }
        
        # Get production stats
        production_stats = ProductionStatsService.calculate(parcel)
        
        # Get findings distribution
        findings_distribution = FindingsDistributionService.calculate(parcel)
        
        # Get species stats
        species_stats = SpeciesStatsService.calculate(parcel)
        
        # Get replacement ratio
        replacement_ratio = ReplacementRatioService.calculate(parcel)
        
        # Combine all stats in a single hash
        {
          parcel: parcel,
          **basic_stats,
          production_stats: production_stats,
          findings_distribution: findings_distribution,
          species_stats: species_stats,
          replacement_ratio: replacement_ratio
        }
      end
    rescue => e
      Rails.logger.error("Error calculating all statistics for parcel #{parcel.id}: #{e.message}")
      
      # Return a minimal stats object if there's an error
      {
        parcel: parcel,
        total_locations: parcel.locations_count || 0,
        total_plantings: parcel.plantings_count || 0,
        findings_count: parcel.findings_count || 0,
        production_stats: { 
          total: "0g", 
          per_location: "0g", 
          per_planting: "0g", 
          per_producing_planting: "0g" 
        },
        findings_distribution: {
          no_findings: 0,
          one_finding: 0,
          two_findings: 0,
          three_findings: 0,
          four_plus_findings: 0,
          replacements: 0
        },
        species_stats: [],
        replacement_ratio: 0
      }
    end
  end
  
  private
  
  def self.in_peak_season?
    # Check if current date is in peak season (typically April - October)
    current_month = Time.zone.now.month
    (4..10).include?(current_month)
  end
end
