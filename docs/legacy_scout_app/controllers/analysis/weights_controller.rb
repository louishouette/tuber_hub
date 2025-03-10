module Analysis
  class WeightsController < ApplicationController
    include Seasonable
    include WeekFormattable

    def index
      # Species weights
      @species_weights = Finding.in_current_season
                              .joins(location: { location_plantings: { planting: :species } })
                              .select('findings.*', 'species.id as species_id', 'species.name as species_name')
                              .group('species.id')
                              .group_by_week('findings.created_at', week_start: :monday)
                              .average('COALESCE(findings.finding_raw_weight, findings.finding_averaged_raw_weight)')
                              .transform_keys { |k| [Species.find(k[0]).name, k[1]] }
                              .transform_values { |v| v&.round }
                              .reject { |_, v| v.nil? || v.zero? }
                              .sort_by { |k, _| [k[0], k[1].strftime('%G').to_i, k[1].strftime('%V').to_i] }  # Sort by species name first, then ISO week
                              .map { |k, v| [[k[0], format_week(k[1].to_date)], v] }
                              .to_h

      Rails.logger.debug "Species weights: #{@species_weights.inspect}"

      # Get parcels with their spring ages (cached for 1 hour)
      @parcels_by_age = Rails.cache.fetch('parcels_by_spring_age', expires_in: 1.hour) do
        # Get all parcels with their planted_at dates, only those older than 3 springs
        Parcel.where.not(planted_at: nil)
              .select { |parcel| parcel.spring_age >= 3 }
              .group_by { |parcel| parcel.spring_age }
              .sort.reverse.to_h  # Sort by age in descending order
      end

      @parcel_weights_by_age = {}
      @parcels_by_age.each do |age, parcels|
        # Get all findings for these parcels in the current season
        findings = Finding.in_current_season
                        .joins(location: [:row, { location_plantings: { planting: :species } }])
                        .where(rows: { parcel_id: parcels.map(&:id) })
                        .select('findings.*, species.id as species_id, species.name as species_name, findings.created_at')

        # Group findings by week starting from Monday
        findings_by_week = findings.group_by { |f| f.created_at.beginning_of_week(:monday).to_date }

        # Calculate average weights only for weeks with enough findings
        weights_by_species = {}
        findings_by_week.each do |week, week_findings|
          next if week_findings.count < 20  # Skip weeks with insufficient findings

          # Group this week's findings by species
          by_species = week_findings.group_by(&:species_name)
          
          by_species.each do |species_name, species_findings|
            weights = species_findings.map { |f| f.finding_raw_weight || f.finding_averaged_raw_weight }.compact
            next if weights.empty?

            avg_weight = (weights.sum / weights.size).round
            weights_by_species[species_name] ||= {}
            weights_by_species[species_name][format_week(week)] = avg_weight
          end
        end

        next if weights_by_species.empty?

        # Sort each species data by week
        weights_by_species.each do |species, data|
          weights_by_species[species] = data.sort_by { |week_str, _| 
            parse_week_string(week_str)  # Use the helper from WeekFormattable
          }.to_h
        end

        @parcel_weights_by_age[age] = {
          parcels: parcels.sort_by(&:name),
          weights_by_species: weights_by_species
        }
      end

      # Findings vs Weights
      findings_data = Finding.in_current_season
                           .group_by_week('created_at', week_start: :monday)
                           .count
                           .transform_keys { |k| format_week(k.to_date) }
                           .sort_by { |k, _| parse_week_string(k) }
                           .to_h

      weights_data = Finding.in_current_season
                          .group_by_week('created_at', week_start: :monday)
                          .average('COALESCE(finding_raw_weight, finding_averaged_raw_weight)')
                          .transform_values { |v| v&.round }
                          .transform_keys { |k| format_week(k.to_date) }
                          .sort_by { |k, _| parse_week_string(k) }
                          .to_h

      @findings_vs_weights = {
        findings: findings_data,
        weights: weights_data
      }
    end
  end
end
