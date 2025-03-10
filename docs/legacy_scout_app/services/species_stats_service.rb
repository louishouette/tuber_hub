class SpeciesStatsService
  def self.calculate(parcel)
    # Use Rails cache to avoid recalculating for the same parcel
    Rails.cache.fetch("species_stats/parcel/#{parcel.id}", expires_in: 1.hour) do
      begin
        # Get species statistics with a single query
        species_stats = Species
          .joins(plantings: { location_planting: { location: { row: :parcel } } })
          .where(parcels: { id: parcel.id })
          .select('species.id, species.name')
          .select('COUNT(DISTINCT location_plantings.id) as planting_count')
          .select('COUNT(DISTINCT findings.id) as findings_count')
          .select('SUM(COALESCE(findings.finding_raw_weight, findings.finding_averaged_raw_weight, 0)) as total_weight')
          .select('SUM(COALESCE(findings.finding_raw_weight, findings.finding_averaged_raw_weight, 0)) / NULLIF(COUNT(DISTINCT location_plantings.id), 0) as weight_per_planting')
          .left_joins(plantings: { location_planting: { location: :findings } })
          .group('species.id, species.name')
          .order(Arel.sql('weight_per_planting DESC'))

        # Return empty array if no species stats found
        return [] if species_stats.empty?

        # Get locations with a single planting for each species
        never_replaced_counts = {}
        
        species_stats.each do |stat|
          # For each species, find locations that have only one planting of this species
          never_replaced = Location
            .joins(row: :parcel)
            .where(rows: { parcel_id: parcel.id })
            .joins(:location_plantings => { :planting => :species })
            .where(species: { id: stat.id })
            .group('locations.id')
            .having('COUNT(location_plantings.id) = 1')
            .count
            .size
            
          never_replaced_counts[stat.id] = never_replaced
        end

        # Transform the results into the expected format
        species_stats.map do |stat|
          findings_count = stat.findings_count.to_i
          total_weight = stat.total_weight.to_f || 0
          planting_count = stat.planting_count.to_i
          
          {
            species: stat,
            planting_count: planting_count,
            never_replaced_count: never_replaced_counts[stat.id] || 0,
            findings_count: findings_count,
            total_weight: total_weight.round,
            avg_weight: findings_count > 0 ? (total_weight / findings_count).round : 0,
            production_per_planting: planting_count > 0 ? (total_weight / planting_count).round(2) : 0
          }
        end
      rescue => e
        Rails.logger.error("Error calculating species stats for parcel #{parcel.id}: #{e.message}")
        return []
      end
    end
  end
end
