class ProductionStatsService
  def self.calculate(parcel)
    # Use Rails cache to avoid recalculating for the same parcel
    Rails.cache.fetch("production_stats/parcel/#{parcel.id}", expires_in: 1.hour) do
      begin
        # Get current season date range
        inoculation_id = Inoculation.first&.id
        
        if inoculation_id
          season_start = Finding.current_season_start(inoculation_id)
          season_end = Finding.current_season_end(inoculation_id)
          
          # Get production statistics with a simple query without any ordering
          findings = Finding
            .joins(location: { row: :parcel })
            .where(parcels: { id: parcel.id })
            .where(created_at: season_start..season_end)
            .to_a
            
          # Calculate statistics manually
          findings_count = findings.size
          total_weight = findings.sum { |f| f.finding_raw_weight || f.finding_averaged_raw_weight || 0 }
          locations_with_findings = findings.map { |f| f.location_id }.uniq.size
        else
          # If no inoculation exists, create empty stats
          findings_count = 0
          total_weight = 0
          locations_with_findings = 0
        end

        # Get total locations in a separate query
        total_locations = Location.joins(row: :parcel).where(rows: { parcel_id: parcel.id }).count

        # Ensure we don't divide by zero
        locations_with_findings = 1 if locations_with_findings.zero?
        total_locations = 1 if total_locations.zero?

        # Return hash with formatted values
        {
          total: "#{total_weight.round}g",
          per_location: "#{(total_weight / locations_with_findings).round(2)}g",
          per_planting: "#{(total_weight / total_locations).round(2)}g",
          per_producing_planting: "#{(total_weight / locations_with_findings).round(2)}g"
        }
      rescue => e
        Rails.logger.error("Error calculating production stats for parcel #{parcel.id}: #{e.message}")
        return {
          total: "0g",
          per_location: "0g",
          per_planting: "0g",
          per_producing_planting: "0g"
        }
      end
    end
  end
end
