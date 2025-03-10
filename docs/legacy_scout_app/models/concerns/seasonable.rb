module Seasonable
  extend ActiveSupport::Concern

  included do
    class_attribute :seasonable_date_field, default: :created_at
  end

  class_methods do
    def season_start_for_date(inoculation_id, date)
      inoculation = Inoculation.find(inoculation_id)
      Time.zone.local(
        date.month < inoculation.season_start_month ? date.year - 1 : date.year,
        inoculation.season_start_month,
        1
      )
    end

    def season_end_for_date(inoculation_id, date)
      inoculation = Inoculation.find(inoculation_id)
      start_date = season_start_for_date(inoculation_id, date)
      start_date + inoculation.season_duration_months.months - 1.day
    end

    def current_season_start(inoculation_id)
      season_start_for_date(inoculation_id, Time.zone.now)
    end

    def current_season_end(inoculation_id)
      season_end_for_date(inoculation_id, Time.zone.now)
    end

    def previous_season_start(inoculation_id)
      inoculation = Inoculation.find(inoculation_id)
      current_start = current_season_start(inoculation_id)
      season_start_for_date(inoculation_id, current_start - inoculation.season_duration_months.months)
    end

    def previous_season_end(inoculation_id)
      inoculation = Inoculation.find(inoculation_id)
      current_start = current_season_start(inoculation_id)
      season_end_for_date(inoculation_id, current_start - inoculation.season_duration_months.months)
    end

    def current_season_range(inoculation_id)
      current_season_start(inoculation_id)..current_season_end(inoculation_id)
    end

    def previous_season_range(inoculation_id)
      previous_season_start(inoculation_id)..previous_season_end(inoculation_id)
    end

    def season_weeks(inoculation_id)
      (current_season_start(inoculation_id).to_date..current_season_end(inoculation_id).to_date)
        .step(7)
        .map { |date| date.beginning_of_week(:monday) }
        .uniq
    end

    def in_season(inoculation_id, date = Time.zone.now)
      where(seasonable_date_field => season_range_for_date(inoculation_id, date))
    end

    def season_range_for_date(inoculation_id, date)
      inoculation = Inoculation.find(inoculation_id)
      start_date = Time.zone.local(
        date.month < inoculation.season_start_month ? date.year - 1 : date.year,
        inoculation.season_start_month,
        1
      )
      end_date = start_date + inoculation.season_duration_months.months - 1.day
      start_date..end_date
    end
    
    # Determines if a planting date belongs to the original plantings of a season
    # 
    # A planting is considered an "original planting" for a season if it was planted 
    # before the start of that season but not earlier than the previous season.
    # This is important for yield calculations, as these plantings had the full season
    # to potentially produce truffles.
    #
    # NOTE: This method only checks planting dates. For a more comprehensive approach, use
    # get_active_plantings_at_season_start which considers the complete location/planting history.
    #
    # @param inoculation_id [Integer] The ID of the inoculation to use for season calculation
    # @param planting_date [Date, Time] The planting date to check
    # @param target_season_start [Date, Time] The start date of the target season
    # @return [Boolean] true if the planting belongs to the original plantings of the season
    def is_original_planting_for_season?(inoculation_id, planting_date, target_season_start)
      # Safety checks for nil values
      return false if planting_date.nil? || target_season_start.nil?
      
      # Convert inputs to Time objects in the current time zone for consistent comparison
      planting_time = planting_date.is_a?(Time) ? planting_date : planting_date.to_time.in_time_zone
      target_season = target_season_start.is_a?(Time) ? target_season_start : target_season_start.to_time.in_time_zone
      
      # If the planting was made on or after the season start, it's not an original planting
      # for this season
      return false if planting_time >= target_season
      
      # Get the inoculation to calculate the previous season start
      inoculation = Inoculation.find(inoculation_id)
      
      # Calculate the previous season's start date
      prev_season_start = Time.zone.local(
        target_season.year - 1,
        inoculation.season_start_month,
        1
      )
      
      # A planting is an "original planting" for the first season after it was planted
      # If it was planted before the previous season, it's not an original planting for this season
      return planting_time >= prev_season_start
    end
    
    # Get all active plantings for a parcel at the start of a season
    # 
    # This method identifies which plantings were active at each location in a parcel
    # at the start of a specific season.
    #
    # @param parcel_id [Integer] The ID of the parcel to check
    # @param season_start [Date, Time] The start date of the season
    # @return [Hash] A hash where keys are location IDs and values are active plantings
    def get_active_plantings_at_season_start(parcel_id, season_start)
      # Convert season_start to Time for consistent comparison
      start_date = season_start.is_a?(Time) ? season_start : season_start.to_time.in_time_zone
      
      # Find all locations in the parcel
      locations = Location.joins(row: :parcel).where(parcels: { id: parcel_id })
      
      # Build a hash of location_id => active_planting
      active_plantings = {}
      
      locations.each do |location|
        active_planting = location.actual_planting_at(start_date)
        active_plantings[location.id] = active_planting if active_planting.present?
      end
      
      active_plantings
    end
    
    # Get replacements that occurred during a season
    # 
    # This method identifies plantings that were replaced during a specific season.
    # A replacement is identified when a location has a planting with a planted_at date
    # within the season range.
    #
    # @param parcel_id [Integer] The ID of the parcel to check
    # @param season_start [Date, Time] The start date of the season
    # @param season_end [Date, Time] The end date of the season
    # @return [Array] An array of hashes containing location and replacement information
    def get_replacements_in_season(parcel_id, season_start, season_end)
      # Convert dates to Time for consistent comparison
      start_date = season_start.is_a?(Time) ? season_start : season_start.to_time.in_time_zone
      end_date = season_end.is_a?(Time) ? season_end : season_end.to_time.in_time_zone
      
      # Find all locations in the parcel
      locations = Location.joins(row: :parcel).where(parcels: { id: parcel_id })
      
      replacements = []
      
      locations.each do |location|
        # Find plantings made during this season (these are replacements)
        replacement_plantings = location.plantings.where(planted_at: start_date..end_date)
                                         .order(planted_at: :asc)
        
        replacement_plantings.each do |replacement|
          # Find the previous planting that was replaced
          previous_planting = location.plantings
                                     .where('planted_at < ?', replacement.planted_at)
                                     .order(planted_at: :desc)
                                     .first
          
          if previous_planting.present?
            replacements << {
              location: location,
              previous_planting: previous_planting,
              replacement_planting: replacement,
              replaced_at: replacement.planted_at,
              same_species: previous_planting.species_id == replacement.species_id
            }
          end
        end
      end
      
      replacements
    end
    
    # Get the original (first) plantings for each location in a parcel
    # 
    # This method returns the historically first planting at each location in a parcel.
    # These are the original plantings regardless of whether they have been replaced.
    #
    # @param parcel_id [Integer] The ID of the parcel to check
    # @return [Hash] A hash where keys are location IDs and values are the original plantings
    def get_original_plantings_for_parcel(parcel_id)
      # Find all locations in the parcel
      locations = Location.joins(row: :parcel).where(parcels: { id: parcel_id })
      
      # Build a hash of location_id => original_planting
      original_plantings = {}
      
      locations.each do |location|
        original_planting = location.original_planting
        original_plantings[location.id] = original_planting if original_planting.present?
      end
      
      original_plantings
    end

    # Compare plantings across two seasons to identify changes
    # 
    # This method compares the active plantings at the start of two different seasons
    # to identify what changed between them (replacements, new plantings, etc.)
    #
    # @param parcel_id [Integer] The ID of the parcel to check
    # @param season1_start [Date, Time] The start date of the first season
    # @param season2_start [Date, Time] The start date of the second season
    # @return [Hash] A hash containing statistics about changes between the seasons
    def compare_season_plantings(parcel_id, season1_start, season2_start)
      # Get active plantings for both seasons
      plantings_season1 = get_active_plantings_at_season_start(parcel_id, season1_start)
      plantings_season2 = get_active_plantings_at_season_start(parcel_id, season2_start)
      
      # Track various types of changes
      comparison = {
        same_plantings: [],        # Locations with the same planting in both seasons
        replaced_plantings: [],    # Locations where the planting was replaced
        species_changes: [],       # Locations where the species changed
        new_plantings: [],         # Locations that had no planting in season1 but do in season2
        lost_plantings: []         # Locations that had a planting in season1 but not in season2
      }
      
      # Check all locations from season1
      plantings_season1.each do |location_id, planting1|
        if plantings_season2.key?(location_id)
          planting2 = plantings_season2[location_id]
          
          if planting1.id == planting2.id
            # Same planting in both seasons
            comparison[:same_plantings] << { location_id: location_id, planting: planting1 }
          else
            # Planting was replaced
            change = { 
              location_id: location_id, 
              old_planting: planting1, 
              new_planting: planting2 
            }
            comparison[:replaced_plantings] << change
            
            # Check if species changed
            if planting1.species_id != planting2.species_id
              comparison[:species_changes] << change
            end
          end
          
          # Remove from season2 hash to track what's left
          plantings_season2.delete(location_id)
        else
          # Planting exists in season1 but not in season2
          comparison[:lost_plantings] << { location_id: location_id, planting: planting1 }
        end
      end
      
      # Any remaining plantings in season2 are new compared to season1
      plantings_season2.each do |location_id, planting|
        comparison[:new_plantings] << { location_id: location_id, planting: planting }
      end
      
      comparison
    end
    
    # Get all previous seasons up to the current season
    # @param inoculation_id [Integer] The ID of the inoculation to use for season calculation
    # @param limit [Integer] The maximum number of seasons to return
    # @return [Array] Array of hashes containing season information
    def get_all_seasons(inoculation_id, limit = 10)
      seasons = []
      current_time = Time.zone.now
      
      # Get current season details
      current_season_start = current_season_start(inoculation_id)
      current_season_end = current_season_end(inoculation_id)
      
      # If we're between seasons, use the upcoming season
      if current_time > current_season_end
        inoculation = Inoculation.find(inoculation_id)
        next_season_start = Time.zone.local(current_season_start.year + 1, inoculation.season_start_month, 1)
        next_season_end = next_season_start + inoculation.season_duration_months.months - 1.day
        
        seasons << {
          start_date: next_season_start,
          end_date: next_season_end,
          display: "#{next_season_start.year}-#{next_season_end.year}"
        }
      end
      
      # Add current season
      seasons << {
        start_date: current_season_start,
        end_date: current_season_end,
        display: "#{current_season_start.year}-#{current_season_end.year}"
      }
      
      # Add previous seasons
      season_start = current_season_start
      season_end = current_season_end
      inoculation = Inoculation.find(inoculation_id)
      
      (limit - seasons.size).times do
        # Move to the previous season
        season_end = season_start - 1.day
        season_start = season_start_for_date(inoculation_id, season_start - inoculation.season_duration_months.months)
        
        seasons << {
          start_date: season_start,
          end_date: season_end,
          display: "#{season_start.year}-#{season_end.year}"
        }
      end
      
      seasons
    end
  end
end