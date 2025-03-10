class ReplacementRatioService
  def self.calculate(parcel)
    return 0.0 unless parcel&.id

    begin
      # Use Rails cache to avoid recalculating for the same parcel
      Rails.cache.fetch("replacement_ratio/parcel/#{parcel.id}", expires_in: 1.hour) do
        calculate_without_cache(parcel)
      end
    rescue => e
      # Log the error and return a safe default
      Rails.logger.error("Cache error in ReplacementRatioService for parcel #{parcel.id}: #{e.message}")
      calculate_without_cache(parcel)
    end
  end

  def self.calculate_without_cache(parcel)
    begin
      # Get total locations
      total_locations = Location.joins(row: :parcel)
                              .where(rows: { parcel_id: parcel.id })
                              .count
      
      return 0.0 if total_locations.zero?
      
      # Get locations with multiple plantings (replacements)
      replaced_locations = Location
        .joins(row: :parcel)
        .where(rows: { parcel_id: parcel.id })
        .joins(:location_plantings)
        .group('locations.id')
        .having('COUNT(location_plantings.id) > 1')
        .count
        .size
      
      # Calculate the ratio and round to 1 decimal place
      (replaced_locations.to_f / total_locations * 100).round(1)
    rescue => e
      # Log the error and return a safe default
      Rails.logger.error("Error in ReplacementRatioService for parcel #{parcel.id}: #{e.message}")
      0.0
    end
  end
end
