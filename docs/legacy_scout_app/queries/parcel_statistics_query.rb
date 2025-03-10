class ParcelStatisticsQuery
  def initialize(orchards, filters = {})
    @orchards = orchards
    @filters = filters
    @season = filters[:season] || 'current'
  end
  
  # Get the statistics for all parcels
  # Returns a hash with orchard_id as keys and arrays of stats as values
  def execute
    begin
      result = {}
      
      # Debug information
      Rails.logger.debug("ParcelStatisticsQuery#execute - Filters: #{@filters.inspect}")
      Rails.logger.debug("ParcelStatisticsQuery#execute - Orchards: #{@orchards.pluck(:id, :name)}")
      
      # For each orchard, get the statistics for its parcels
      @orchards.each do |orchard|
        # Get filtered parcels for this orchard
        parcels = filtered_parcels_for_orchard(orchard)
        
        # Debug parcels count
        Rails.logger.debug("ParcelStatisticsQuery#execute - Orchard #{orchard.id} (#{orchard.name}) has #{parcels.count} parcels after filtering")
        
        # Skip if no parcels match the filter
        next if parcels.empty?
        
        # Get enhanced statistics for each parcel
        stats = parcels.map do |parcel|
          begin
            # Get stats with specific season
            Rails.logger.debug("Getting enhanced statistics for parcel #{parcel.id} with season #{@season}")
            parcel.get_enhanced_statistics(season: @season)
          rescue => e
            Rails.logger.error("Error getting stats for parcel #{parcel.id}: #{e.message}")
            # Return a minimal hash with just the ID and name
            {
              id: parcel.id,
              name: parcel.name,
              error: e.message
            }
          end
        end
        
        # Store the stats
        result[orchard.id] = stats
      end
      
      # Debug result
      Rails.logger.debug("ParcelStatisticsQuery#execute - Final result has #{result.keys.size} orchards and #{result.values.flatten.size} parcels")
      
      result
    rescue => e
      Rails.logger.error("Error in ParcelStatisticsQuery#execute: #{e.message}")
      {}
    end
  end
  
  private
  
  def filtered_parcels_for_orchard(orchard)
    # Start with all parcels for this orchard
    parcels = orchard.parcels
    
    # Log the initial count
    Rails.logger.debug("Orchard #{orchard.id} (#{orchard.name}) has #{parcels.count} parcels initially")
    
    # If no filters are applied, return all parcels for this orchard
    if @filters.empty? || (@filters.keys - [:season]).empty?
      Rails.logger.debug("No filters applied, returning all parcels for orchard #{orchard.id}")
      return parcels.to_a
    end
    
    # Apply specific parcel filtering
    if @filters[:parcel_ids].present?
      Rails.logger.debug("Filtering by parcel_ids: #{@filters[:parcel_ids]}")
      parcels = parcels.where(id: @filters[:parcel_ids])
    end
    
    # Apply filters
    # Single species filter
    if @filters[:species_id].present?
      parcels = parcels.joins(rows: { locations: :plantings })
                      .where(plantings: { species_id: @filters[:species_id] })
                      .distinct
    end
    
    # Multiple species filter
    if @filters[:species_ids].present?
      species_ids = Array(@filters[:species_ids])
      
      begin
        # Get a simple list of all parcels that have these species
        qualifying_parcel_ids = Set.new
        
        # Only run if we have parcel IDs to check
        if parcels.exists?
          # For each species, find parcels that have it
          species_ids.each do |species_id|
            # This query finds parcels with the given species
            sql = <<-SQL
              SELECT DISTINCT parcels.id 
              FROM parcels
              INNER JOIN rows ON rows.parcel_id = parcels.id
              INNER JOIN locations ON locations.row_id = rows.id
              INNER JOIN location_plantings ON location_plantings.location_id = locations.id
              INNER JOIN plantings ON plantings.id = location_plantings.planting_id
              WHERE parcels.id IN (#{parcels.pluck(:id).join(',')})
              AND plantings.species_id = #{species_id.to_i}
            SQL
            
            # Get the parcel IDs that match this species
            parcel_ids_with_species = ActiveRecord::Base.connection.execute(sql).to_a.map { |r| r["id"] }
            
            # Add to our set of qualifying parcels
            qualifying_parcel_ids.merge(parcel_ids_with_species)
          end
          
          # If we found matching parcels, filter the original collection
          if qualifying_parcel_ids.any?
            parcels = parcels.where(id: qualifying_parcel_ids.to_a)
          else
            parcels = parcels.where(id: nil) # Empty result set
          end
        end
      rescue => e
        Rails.logger.error("Error filtering by species: #{e.message}")
        # Continue with original parcels if there's an error
      end
    end
    
    # Rootstock filter removed - not part of this application
    
    # Apply age filters
    current_year = Time.zone.now.year
    
    # Handle spring age filtering
    begin
      spring_ages = nil
      
      # First try the spring_ages_filter parameter (from our controller)
      if @filters[:spring_ages_filter].present?
        spring_ages = Array(@filters[:spring_ages_filter])
      # Fallback to spring_age parameter if needed
      elsif @filters[:spring_age].present?
        spring_ages = Array(@filters[:spring_age])
      end
      
      # Process spring ages if we found them from either parameter
      if spring_ages.present?
        # Ensure spring_ages are integers and valid
        valid_ages = spring_ages.map(&:to_i).select { |age| age >= 0 }
        
        if !valid_ages.empty?
          # Calculate spring age with proper reference dates
          reference_date = Time.zone.now
          december_first = Date.new(reference_date.year, 12, 1)
          december_first = Date.new(reference_date.year - 1, 12, 1) if reference_date.to_date < december_first
          january_first = Date.new(december_first.year, 1, 1)
          
          Rails.logger.info("Spring age calculation based on:")
          Rails.logger.info("  Reference date: #{reference_date}")
          Rails.logger.info("  December 1st: #{december_first}")
          Rails.logger.info("  January 1st: #{january_first}")
          Rails.logger.info("  Spring ages to filter: #{valid_ages.inspect}")
          
          # Get sample parcel data before filtering
          if parcels.exists?
            sample_before = parcels.limit(3).pluck(:id, :name, :planted_at)
            Rails.logger.info("Sample parcels before filtering (ID, Name, Planted At): #{sample_before.inspect}")
          end
          
          # Initialize a combined query for all spring ages
          spring_query = nil
          
          # Process each spring age individually
          valid_ages.each do |age|
            # The model's with_spring_age scope generates a SQL condition
            # But we need to apply it differently in this context
            Rails.logger.info("==== APPLYING SPRING AGE FILTER: #{age} =====")
            # Try direct SQL approach first for debugging
            reference_date = Time.zone.now
            december_first = Date.new(reference_date.year, 12, 1)
            december_first = Date.new(reference_date.year - 1, 12, 1) if reference_date.to_date < december_first
            january_first = Date.new(december_first.year, 1, 1)
            
            # Add specific debug for SQL
            sql_condition = "planted_at IS NOT NULL AND planted_at < ? AND (EXTRACT(YEAR FROM ?::date) - EXTRACT(YEAR FROM planted_at)) = ?"
            sub_query = parcels.where([sql_condition, january_first, december_first, age])
            Rails.logger.info("Direct SQL Query: #{sub_query.to_sql}")
            count_pre = sub_query.count
            Rails.logger.info("Pre-check count: #{count_pre}")
            
            # Now try with the scope - force table disambiguation to ensure correct SQL generation
            base_ids = parcels.pluck(:id) # get the IDs from our current scope
            with_spring_age_sql = Parcel.with_spring_age(age).to_sql
            Rails.logger.info("Raw with_spring_age SQL: #{with_spring_age_sql}")
            
            # PRIMARY METHOD: Use the model scope with explicit subquery approach
            age_query = Parcel.where(id: base_ids).merge(Parcel.with_spring_age(age))
            count = age_query.count
            
            # If we got zero results, try a direct SQL approach as a fallback
            if count == 0 && Parcel.with_spring_age(age).exists?
              Rails.logger.warn("⚠️ Zero results with regular merge, trying direct SQL as fallback")
              
              # Fallback method: Use raw SQL directly
              reference_date = Time.zone.now
              december_first = Date.new(reference_date.year, 12, 1)
              december_first = Date.new(reference_date.year - 1, 12, 1) if reference_date.to_date < december_first
              january_first = Date.new(december_first.year, 1, 1)
              
              # Build SQL directly
              direct_sql = ActiveRecord::Base.sanitize_sql_array([
                "SELECT parcels.* FROM parcels WHERE parcels.id IN (?) " +
                "AND parcels.planted_at IS NOT NULL " +
                "AND parcels.planted_at <= ? " +
                "AND (? - DATE_PART('year', parcels.planted_at)) = ?",
                base_ids, january_first, december_first.year, age
              ])
              
              Rails.logger.warn("Direct SQL: #{direct_sql}")
              
              # Execute the query directly
              age_query = Parcel.find_by_sql(direct_sql)
              count = age_query.size
              Rails.logger.warn("Direct SQL found #{count} results")
            end
            
            Rails.logger.info("Spring age #{age} query: #{age_query.to_sql}")
            Rails.logger.info("Found #{count} parcels with spring age #{age}")
            
            # Sample some matching parcels for debugging
            if count > 0
              sample = age_query.limit(2).pluck(:id, :name, :planted_at) 
              Rails.logger.info("Sample parcels with spring age #{age}: #{sample.inspect}")
            end
            
            # Combine with OR logic
            if spring_query.nil?
              spring_query = age_query
            else
              spring_query = spring_query.or(age_query)
            end
          end
          
          # Apply the final query if we found any matches
          if spring_query.present?
            Rails.logger.info("SPRING AGE SQL: #{spring_query.to_sql}")
            
            # Ensure we only get the parcels from our original scope
            parcels_with_spring_age = spring_query
            
            # Count before final assignment
            count_before_final = parcels_with_spring_age.count
            Rails.logger.info("After filtering, found #{count_before_final} parcels")
            
            # Final assignment
            parcels = parcels_with_spring_age
            
            # Verify count after assignment
            final_count = parcels.count
            Rails.logger.info("Final count after assignment: #{final_count}")
            
            # Sample debug if count changed
            if count_before_final != final_count
              Rails.logger.warn("WARNING: Count changed from #{count_before_final} to #{final_count}!")
              Rails.logger.info("Final parcels: #{parcels.limit(5).pluck(:id)}")
            end
          else
            Rails.logger.info("No parcels matched any spring age criteria")
          end
          
          Rails.logger.info("=========== END SPRING AGE FILTER DEBUG =============\n\n")
        end
      elsif @filters[:age_min].present? || @filters[:age_max].present?
        # Standard age range filtering if spring_ages not specified
        if @filters[:age_min].present? && @filters[:age_max].present? && @filters[:age_min] == @filters[:age_max]
          # If min and max are the same, use the spring_age scope directly
          age_value = @filters[:age_min]
          Rails.logger.info("Using derived spring age filter: #{age_value}")
          parcels = Parcel.with_spring_age(age_value).where(id: parcels.select(:id))
        else
          # Otherwise use the year-based filtering for ranges
          if @filters[:age_min].present?
            max_plant_year = current_year - @filters[:age_min].to_i
            Rails.logger.info("Filtering parcels with minimum age #{@filters[:age_min]} years (planted in/before #{max_plant_year})")
            parcels = parcels.where('EXTRACT(YEAR FROM planted_at) <= ?', max_plant_year)
          end
          
          if @filters[:age_max].present?
            min_plant_year = current_year - @filters[:age_max].to_i
            Rails.logger.info("Filtering parcels with maximum age #{@filters[:age_max]} years (planted in/after #{min_plant_year})")
            parcels = parcels.where('EXTRACT(YEAR FROM planted_at) >= ?', min_plant_year)
          end
        end
      end
    rescue => e
      Rails.logger.error("Error applying spring age filters: #{e.message}\n#{e.backtrace.join("\n")}")
      # Continue with the original parcels if there was an error
    end
    
    # Log the filtered count
    Rails.logger.debug("After filtering, orchard #{orchard.id} has #{parcels.count} parcels")
    
    # Apply date range filters
    if @filters[:date_from].present?
      parcels = parcels.where('planted_at >= ?', @filters[:date_from])
    end
    
    if @filters[:date_to].present?
      parcels = parcels.where('planted_at <= ?', @filters[:date_to])
    end
    
    # Apply production filter (has produced or not)
    if @filters.key?(:produced)
      if @filters[:produced]
        # Parcels that have produced
        parcels = parcels.joins(rows: { locations: :findings }).distinct
      else
        # Parcels that have not produced
        parcels = parcels.left_joins(rows: { locations: :findings })
                         .where(findings: { id: nil })
                         .distinct
      end
    end
    
    # Plantation type filter removed - column does not exist
    
    parcels
  end
  
  # Rootstock validation method removed - not part of this application
end
