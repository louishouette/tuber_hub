module Filterable
  extend ActiveSupport::Concern
  
  # This module provides filter functionality for controllers
  # It extracts filter parameters and builds a hash of applied filters
  
  # Process filter parameters and return a hash of applied filters
  def process_filters(params)
    filters = {}
    
    # Debug the incoming params
    Rails.logger.info("PROCESS FILTERS - Raw params: #{params.to_unsafe_h.select { |k, v| %w[species_ids spring_age].include?(k) }.inspect}")
    
    # Avoid processing if no params provided
    return filters unless params
    
    # Extract orchard filter
    if params[:orchard].present? && params[:orchard] != 'all'
      filters[:orchard_id] = params[:orchard].to_i
    end
    
    # Extract orchards filter (multiple)
    if params[:orchard_ids].present? && params[:orchard_ids].is_a?(Array)
      filters[:orchard_ids] = params[:orchard_ids].reject(&:blank?).map(&:to_i)
    end
    
    # Extract parcel filter (multiple)
    if params[:parcel_ids].present? && params[:parcel_ids].is_a?(Array)
      filters[:parcel_ids] = params[:parcel_ids].reject(&:blank?).map(&:to_i)
    end
    
    # Extract species filter - single species
    if params[:species].present? && params[:species] != 'all'
      filters[:species_id] = params[:species].to_i
    end
    
    # Extract species filter - multiple species
    if params[:species_ids].present?
      # Handle both arrays and scalar values
      Rails.logger.info("SPECIES_IDS DEBUG - Raw: #{params[:species_ids].inspect}, Class: #{params[:species_ids].class}")
      
      if params[:species_ids].is_a?(Array)
        filtered_species = params[:species_ids].reject(&:blank?)
        Rails.logger.info("SPECIES_IDS DEBUG - After filtering blanks: #{filtered_species.inspect}")
        
        if filtered_species.any?
          values = filtered_species.map(&:to_i).select { |id| id > 0 }
          Rails.logger.info("SPECIES_IDS DEBUG - Final IDs for filter: #{values.inspect}")
          if values.any?
            filters[:species_ids] = values
          end
        end
      elsif params[:species_ids].is_a?(String) && params[:species_ids].include?(',')
        # Handle comma-separated string (from URL params)
        values = params[:species_ids].split(',').map(&:to_i).select { |id| id > 0 }
        Rails.logger.info("SPECIES_IDS DEBUG - Comma-separated values: #{values.inspect}")
        if values.any?
          filters[:species_ids] = values
        end
      elsif params[:species_ids].is_a?(String)
        # Handle scalar value
        species_id = params[:species_ids].to_i
        if species_id > 0
          Rails.logger.info("SPECIES_IDS DEBUG - Single species ID: #{species_id}")
          filters[:species_ids] = [species_id]
        end
      end
    end
    
    # Rootstock filter removed - not part of this application
    
    # Extract age filter
    if params[:age_min].present?
      filters[:age_min] = params[:age_min].to_i
    end
    
    if params[:age_max].present?
      filters[:age_max] = params[:age_max].to_i
    end
    
    # FIXED SPRING AGE HANDLING
    # Extract spring age filter (specific age value or multiple values)
    if params[:spring_age].present? || params[:spring_filter_enabled].present?
      # Log the raw value for debugging with a distinctive pattern
      Rails.logger.error("\n\n🌱🌱🌱 SPRING AGE FILTER PROCESSING 🌱🌱🌱")
      Rails.logger.error("Raw spring_age: #{params[:spring_age].inspect} (Class: #{params[:spring_age].class})")
      Rails.logger.error("spring_filter_enabled: #{params[:spring_filter_enabled]}")
      
      # IMPROVED: Get spring age values handling ALL possible parameter formats
      spring_age_values = []
      raw_spring_age = params[:spring_age]
      
      # Special handling for the array syntax with [] in the parameter name
      raw_spring_age_array = params['spring_age[]'] if raw_spring_age.nil? && params['spring_age[]'].present?
      if raw_spring_age_array.present?
        Rails.logger.error("Found alternative spring_age[] parameter: #{raw_spring_age_array.inspect}")
        raw_spring_age = raw_spring_age_array
      end
      
      # Process raw_spring_age regardless of format
      spring_age_values = case raw_spring_age
        when Array
          # Already an array - most common with multiselect
          Rails.logger.error("SPRING_AGE FORMAT: Direct Array - #{raw_spring_age.inspect}")
          raw_spring_age.reject(&:blank?).map(&:to_i).select { |v| v > 0 }
          
        when Hash
          # Sometimes Rails converts arrays to hashes with numeric keys
          Rails.logger.error("SPRING_AGE FORMAT: Hash - #{raw_spring_age.inspect}")
          raw_spring_age.values.reject(&:blank?).map(&:to_i).select { |v| v > 0 }
          
        when String
          if raw_spring_age.include?(',')
            # Comma-separated string (often from URL parameters)
            Rails.logger.error("SPRING_AGE FORMAT: Comma-separated string - #{raw_spring_age}")
            raw_spring_age.split(',').reject(&:blank?).map(&:to_i).select { |v| v > 0 }
          else
            # Single value string
            age = raw_spring_age.to_i
            Rails.logger.error("SPRING_AGE FORMAT: Single value - #{age}")
            age > 0 ? [age] : []
          end
          
        when nil
          # Explicitly handle nil case
          Rails.logger.error("SPRING_AGE FORMAT: nil value")
          []
          
        else
          # Fallback for any other format - try to convert to integer
          Rails.logger.error("SPRING_AGE FORMAT: Unknown (#{raw_spring_age.class}) - #{raw_spring_age.inspect}")
          begin
            value = raw_spring_age.to_i
            value > 0 ? [value] : []
          rescue
            []
          end
      end
      
      # Final spring age values after processing
      if spring_age_values.any?
        Rails.logger.error("✅ SPRING_AGE FILTER: Using values: #{spring_age_values.inspect}")
        filters[:spring_ages_filter] = spring_age_values
      else
        Rails.logger.error("❌ NO VALID SPRING AGE VALUES FOUND - SKIPPING FILTER")
      end
      
      Rails.logger.error("🌱🌱🌱 END SPRING AGE FILTER PROCESSING 🌱🌱🌱\n\n")
    end
    
    # Extract date range
    if params[:date_from].present?
      begin
        filters[:date_from] = Time.zone.parse(params[:date_from])
      rescue
        # Invalid date format, skip this filter
      end
    end
    
    if params[:date_to].present?
      begin
        filters[:date_to] = Time.zone.parse(params[:date_to])
      rescue
        # Invalid date format, skip this filter
      end
    end
    
    # Extract production filter
    if params[:produced].present?
      filters[:produced] = params[:produced] == 'yes'
    end
    
    # Plantation type filter removed - column does not exist
    
    # Extract season filter
    if params[:season].present? && params[:season] != 'current'
      filters[:season] = params[:season]
    else
      # Default to current season
      filters[:season] = 'current'
    end
    
    filters
  end
  
  # Apply filters to a scope
  def apply_filters(scope, filters)
    return scope unless filters.present?
    
    filtered_scope = scope
    
    # Apply orchard filter
    if filters[:orchard_id].present?
      filtered_scope = filtered_scope.where(orchard_id: filters[:orchard_id])
    end
    
    # Apply orchards filter (multiple)
    if filters[:orchard_ids].present? && filters[:orchard_ids].any?
      filtered_scope = filtered_scope.where(orchard_id: filters[:orchard_ids])
    end
    
    # Apply parcels filter (multiple)
    if filters[:parcel_ids].present? && filters[:parcel_ids].any?
      filtered_scope = filtered_scope.where(id: filters[:parcel_ids])
    end
    
    # Apply species filter through joins
    if filters[:species_id].present?
      filtered_scope = filtered_scope.joins(rows: { locations: :plantings })
                                     .where(plantings: { species_id: filters[:species_id] })
                                     .distinct
    end
    
    # Rootstock filtering removed - not part of this application
    
    # Apply age filters
    current_year = Time.zone.now.year
    
    if filters[:age_min].present?
      # Planted before or in the year that would give them the minimum age
      max_plant_year = current_year - filters[:age_min]
      filtered_scope = filtered_scope.where('EXTRACT(YEAR FROM planted_at) <= ?', max_plant_year)
    end
    
    if filters[:age_max].present?
      # Planted in or after the year that would give them the maximum age
      min_plant_year = current_year - filters[:age_max]
      filtered_scope = filtered_scope.where('EXTRACT(YEAR FROM planted_at) >= ?', min_plant_year)
    end
    
    # Apply date range filters
    if filters[:date_from].present?
      filtered_scope = filtered_scope.where('planted_at >= ?', filters[:date_from])
    end
    
    if filters[:date_to].present?
      filtered_scope = filtered_scope.where('planted_at <= ?', filters[:date_to])
    end
    
    # Apply production filter (has produced or not)
    if filters.key?(:produced)
      if filters[:produced]
        # Parcels that have produced
        filtered_scope = filtered_scope.joins(rows: { locations: :findings }).distinct
      else
        # Parcels that have not produced
        # This is a more complex query using a LEFT OUTER JOIN and checking for NULL
        filtered_scope = filtered_scope.left_joins(rows: { locations: :findings })
                                      .where(findings: { id: nil })
                                      .distinct
      end
    end
    
    # Plantation type filter removed - column does not exist
    
    # Return the filtered scope
    filtered_scope
  end
  
  # Build filter options for select dropdowns
  def build_filter_options
    options = {
      orchards: Orchard.order(:name).map { |o| [o.name, o.id] },
      species: Species.order(:name).map { |s| [s.name, s.id] }
      # plantation_types removed - column does not exist
    }
    
    # Rootstock options removed - not part of this application
    
    options
  end
end
