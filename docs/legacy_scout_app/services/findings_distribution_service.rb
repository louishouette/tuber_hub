class FindingsDistributionService
  def self.calculate(parcel)
    # Use Rails cache to avoid recalculating for the same parcel
    Rails.cache.fetch("findings_distribution/parcel/#{parcel.id}", expires_in: 1.hour) do
      begin
        # Get total locations
        total_locations = Location.joins(row: :parcel).where(rows: { parcel_id: parcel.id }).count
        
        # Get locations with findings counts
        findings_counts = Location
          .joins(row: :parcel)
          .where(rows: { parcel_id: parcel.id })
          .left_joins(:findings)
          .group('locations.id')
          .count('findings.id')
        
        # Get locations with multiple plantings (replacements)
        replaced_locations = Location
          .joins(row: :parcel)
          .where(rows: { parcel_id: parcel.id })
          .joins(:location_plantings)
          .group('locations.id')
          .having('COUNT(location_plantings.id) > 1')
          .count
          .size
        
        # Count locations by number of findings
        no_findings = 0
        one_finding = 0
        two_findings = 0
        three_findings = 0
        four_plus_findings = 0
        
        findings_counts.each do |_, count|
          case count
          when 0
            no_findings += 1
          when 1
            one_finding += 1
          when 2
            two_findings += 1
          when 3
            three_findings += 1
          else
            four_plus_findings += 1
          end
        end
        
        # Return hash with counts
        {
          no_findings: no_findings,
          one_finding: one_finding,
          two_findings: two_findings,
          three_findings: three_findings,
          four_plus_findings: four_plus_findings,
          replacements: replaced_locations
        }
      rescue => e
        Rails.logger.error("Error calculating findings distribution for parcel #{parcel.id}: #{e.message}")
        return {
          no_findings: 0,
          one_finding: 0,
          two_findings: 0,
          three_findings: 0,
          four_plus_findings: 0,
          replacements: 0
        }
      end
    end
  end
end
