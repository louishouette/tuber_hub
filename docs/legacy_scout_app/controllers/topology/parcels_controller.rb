class Topology::ParcelsController < ApplicationController
  include Filterable
  
  # Removed breadcrumbs as per requirement
  before_action :load_filter_options, only: %i[index]

  def index
    
    # Get all orchards (will be filtered by user access in the future)
    @orchards = Orchard.all.order(:name)
    return if @orchards.empty?
    
    # Get data for filter dropdowns
    @parcels = Parcel.all.order(:name)
    @species = Species.all.order(:name)
    @inoculations = Inoculation.all.order(:name)

    # Initialize filter params for the view
    @filter_params = {}
    
    # Extract array parameters with proper nil handling
    @filter_params[:orchard_ids] = Array(params[:orchard_ids]).reject(&:blank?)
    @filter_params[:parcel_ids] = Array(params[:parcel_ids]).reject(&:blank?)
    @filter_params[:species_ids] = Array(params[:species_ids]).reject(&:blank?)
    @filter_params[:inoculation_ids] = Array(params[:inoculation_ids]).reject(&:blank?)
    @filter_params[:spring_age] = Array(params[:spring_age]).reject(&:blank?)
    
    # Handle scalar parameters
    @filter_params[:parcel_name] = params[:parcel_name]
    @filter_params[:species_id] = params[:species_id]
    @filter_params[:age_min] = params[:age_min]
    @filter_params[:age_max] = params[:age_max]

    # Process filter parameters
    begin
      @filters = {}
      @report_type = params[:report_type] || "standard"
      
      # Process species IDs
      if @filter_params[:species_ids].present? 
        @filters[:species_ids] = @filter_params[:species_ids].map(&:to_i).select { |id| id > 0 }
      end
      
      # Process spring age
      if @filter_params[:spring_age].present?
        @filters[:spring_ages_filter] = @filter_params[:spring_age].map(&:to_i).select { |age| age >= 0 }
      end
      
      # Process orchard IDs
      if @filter_params[:orchard_ids].present?
        @filters[:orchard_ids] = @filter_params[:orchard_ids].map(&:to_i).select { |id| id > 0 }
      end
      
      # Process parcel IDs
      if @filter_params[:parcel_ids].present?
        @filters[:parcel_ids] = @filter_params[:parcel_ids].map(&:to_i).select { |id| id > 0 }
      end
      
      # Process inoculation IDs
      if @filter_params[:inoculation_ids].present?
        @filters[:inoculation_ids] = @filter_params[:inoculation_ids].map(&:to_i).select { |id| id > 0 }
      end
    rescue => e
      Rails.logger.error("Error processing filters: #{e.message}\n#{e.backtrace.join("\n")}")
      @filters = {}
    end
    
    query = ParcelStatisticsQuery.new(@orchards, @filters)
    @parcel_stats = query.execute
    
    # If we have no results but should have parcels, try a more direct approach
    if @parcel_stats.values.flatten.empty? && Parcel.count > 0
      # Clear out the hash
      @parcel_stats = {}
      
      # Directly get all parcels for each orchard and get their stats
      @orchards.each do |orchard|
        # Get all parcels for this orchard without any filtering
        parcels = orchard.parcels.to_a
        
        if parcels.any?
          # Get the stats for each parcel
          stats = parcels.map do |parcel|
            begin
              parcel.get_enhanced_statistics(season: 'current')
            rescue => e
              Rails.logger.error("Error getting stats for parcel #{parcel.id}: #{e.message}")
              # Return a minimal hash with just the ID and name
              {
                id: parcel.id,
                name: parcel.name,
                parcel: parcel,
                error: e.message
              }
            end
          end
          
          # Add them to the hash
          @parcel_stats[orchard.id] = stats
        end
      end
    end

    # Sort the parcel statistics
    @sort_field = params[:sort_field] || "ratio"
    @sort_direction = params[:sort_direction] || "desc"
    

    
    @parcel_stats = sort_parcel_stats(@parcel_stats, @sort_field, @sort_direction)
    
    # Create presenter for the view
    @presenter = ParcelsIndexPresenter.new(@orchards, @parcel_stats, @filters)

    # Respond to different formats
    respond_to do |format|
      format.html # index.html.erb
      format.xlsx { export_excel }
    end
  end

  def show
    begin
      @parcel = Parcel.find(params[:id])
      @orchard = @parcel.orchard
      
      # Use the presenter to format the parcel data
      @presenter = ParcelPresenter.new(@parcel)
      @stats = @presenter.stats

      # Don't add flash messages for normal navigation
      
      # Get findings across all seasons grouped by day of year
      @findings_per_day = get_findings_per_day(@parcel.id)
      
      # Get available spring ages for this parcel
      current_time = Time.zone.now
      @spring_ages = Planting.joins(location_planting: { location: { row: :parcel } })
                           .where(parcels: { id: @parcel.id })
                           .distinct
                           .map { |planting| planting&.spring_age(current_time) }
                           .compact
                           .uniq
                           .sort
      
      # Default to at least one age (0) if no plantings found
      @spring_ages = [0] if @spring_ages.empty?
                           
      # Get all species used in this parcel
      @species_list = Species.joins(plantings: { location_planting: { location: { row: :parcel } } })
                            .where(parcels: { id: @parcel.id })
                            .distinct
                            .order(:name)
      
      # Use empty array as fallback if no species found                      
      @species_list = [] if @species_list.empty?
                            
      # Get the inoculation for this parcel (from the first planting)
      first_planting = Planting.joins(location_planting: { location: { row: :parcel } })
                             .where(parcels: { id: @parcel.id })
                             .order(planted_at: :asc)
                             .first
      
      if first_planting.nil? || first_planting.inoculation.nil?
        flash[:error] = "Could not determine inoculation for this parcel."
        redirect_to topology_parcels_path
        return
      end
      
      inoculation = first_planting.inoculation
      
      # Get all seasons using the enhanced Seasonable concern
      seasons = Finding.get_all_seasons(inoculation.id)
      @seasons = seasons
                            
      # Create a statistics table organized by spring age, species, and season
      @age_species_stats = {}
      
      # Initialize the data structure with all combinations of spring age, species, and season
      @spring_ages.each do |age|
        @age_species_stats[age] = {}
        
        @species_list.each do |species|
          @age_species_stats[age][species.id] = {}
          
          seasons.each do |season|
            # Use the year of the season start as the season identifier
            season_year = season[:start_date].year
            
            @age_species_stats[age][species.id][season_year] = {
              species: species,
              spring_age: age,
              season: season,
              season_display: season[:display],
              actual_plantings: 0,
              original_plantings: 0,
              findings_count: 0,
              replacements_count: 0,
              production_grams: 0,
              yield_per_plant: 0,
              avg_weight: 0
            }
          end
        end
      end
    rescue => e
      Rails.logger.error("Error in ParcelsController#show: #{e.message}\n#{e.backtrace.join("\n")}")
      flash[:error] = "An error occurred while loading the parcel data."
      redirect_to topology_parcels_path
      return
    end
    
    # Get plantings counts by spring age, species, and season
    begin
      # Get all plantings for this parcel
      plantings = Planting.joins(location_planting: { location: { row: :parcel } })
                          .where(parcels: { id: @parcel.id })
                          .select("plantings.*, plantings.id as planting_id, species_id, planted_at")
      
      # For each planting, determine its spring age and populate the statistics
      plantings.each do |planting|
        begin
          # Skip if planted_at is not set
          next unless planting.planted_at.present?
          
          # Calculate spring age for this planting
          spring_age = planting.spring_age(current_time)
          species_id = planting.species_id
          
          # Skip if we don't have this spring age or species in our data structure
          next unless spring_age && 
                     species_id && 
                     @age_species_stats[spring_age] && 
                     @age_species_stats[spring_age][species_id]
          
          # For each season, check if this planting should be counted
          seasons.each do |season|
            season_year = season[:start_date].year
            season_start = season[:start_date]
            
            # Skip if we don't have this season in our data structure
            next unless @age_species_stats[spring_age][species_id][season_year]
            
            # Check if the planting was made before the end of this season
            planting_time = planting.planted_at.to_time.in_time_zone
            if planting_time <= season[:end_date]
              # Increment actual plantings count for this season
              @age_species_stats[spring_age][species_id][season_year][:actual_plantings] += 1
              
              # Check if this is an original planting for this season
              # An original planting is one that was planted before the start of the season
              # but not earlier than the start of the previous season
              if planting.original_for_season?(season_start)
                @age_species_stats[spring_age][species_id][season_year][:original_plantings] += 1
              end
            end
          end
        rescue => e
          Rails.logger.error("Error processing planting record: #{e.message}")
          next
        end
      end
    rescue => e
      Rails.logger.error("Error querying plantings: #{e.message}")
    end
    
    # Get findings counts, production and averages by spring age, species, and season
    populate_findings_statistics(@parcel.id, @age_species_stats, @seasons, inoculation, current_time)
    
    # Get replacements counts by spring age, species, and season
    begin
      replacements_data = LocationPlanting.joins(location: { row: :parcel }, planting: :species)
                                         .where(parcels: { id: @parcel.id })
                                         .where("location_plantings.replaced_at IS NOT NULL") # Only count actual replacements
                                         .select("location_plantings.*, " +
                                                "location_plantings.replaced_at as replacement_date, " +
                                                "species.id as species_id, " +
                                                "plantings.planted_at as planting_date")
      
      replacements_data.each do |replacement|
        begin
          # Skip if critical data is missing
          next unless replacement.replacement_date && replacement.planting_date && replacement.species_id
          
          # Calculate spring age for this replacement's planting
          planting_date = replacement.planting_date.to_date
          spring_age = if planting_date < Date.new(current_time.year, 1, 1)
                        current_time.year - planting_date.year
                      else
                        0
                      end
          
          species_id = replacement.species_id
          replacement_date = replacement.replacement_date
          
          # Skip if we don't have this spring age or species in our data structure
          next unless spring_age && 
                     species_id && 
                     @age_species_stats[spring_age] && 
                     @age_species_stats[spring_age][species_id]
          
          # Determine which season this replacement belongs to
          seasons.each do |season|
            season_year = season[:start_date].year
            season_range = season[:start_date]..season[:end_date]
            
            # Skip if replacement is not in this season or we don't have this season in our data
            next unless season_range.cover?(replacement_date) && 
                       @age_species_stats[spring_age][species_id][season_year]
            
            # Increment replacements count for this season
            @age_species_stats[spring_age][species_id][season_year][:replacements_count] += 1
            
            # We've found the right season, no need to check other seasons
            break
          end
        rescue => e
          Rails.logger.error("Error processing replacement record: #{e.message}")
          next
        end
      end
    rescue => e
      Rails.logger.error("Error querying replacements: #{e.message}\n#{e.backtrace.join("\n")}")
    end
    
    # Calculate totals per species and per season
    @species_totals = {}
    @season_totals = {}
    
    # Initialize the totals structure
    @species_list.each do |species|
      @species_totals[species.id] = {}
      
      seasons.each do |season|
        season_year = season[:start_date].year
        
        @species_totals[species.id][season_year] = {
          species: species,
          season: season,
          season_display: season[:display],
          actual_plantings: 0,
          original_plantings: 0,
          findings_count: 0,
          replacements_count: 0,
          production_grams: 0,
          yield_per_plant: 0,
          avg_weight: 0
        }
        
        # Initialize season totals if not exists
        @season_totals[season_year] ||= {
          season: season,
          season_display: season[:display],
          actual_plantings: 0,
          original_plantings: 0,
          findings_count: 0,
          replacements_count: 0,
          production_grams: 0,
          yield_per_plant: 0,
          avg_weight: 0
        }
      end
    end
    
    # Calculate species totals across all spring ages for each season
    @spring_ages.each do |age|
      @species_list.each do |species|
        seasons.each do |season|
          season_year = season[:start_date].year
          
          if @age_species_stats[age] && @age_species_stats[age][species.id] && @age_species_stats[age][species.id][season_year]
            stats = @age_species_stats[age][species.id][season_year]
            
            # Add to species totals for this season
            @species_totals[species.id][season_year][:actual_plantings] += stats[:actual_plantings]
            @species_totals[species.id][season_year][:original_plantings] += stats[:original_plantings]
            @species_totals[species.id][season_year][:findings_count] += stats[:findings_count]
            @species_totals[species.id][season_year][:replacements_count] += stats[:replacements_count]
            @species_totals[species.id][season_year][:production_grams] += stats[:production_grams]
            
            # Add to season totals across all species
            @season_totals[season_year][:actual_plantings] += stats[:actual_plantings]
            @season_totals[season_year][:original_plantings] += stats[:original_plantings]
            @season_totals[season_year][:findings_count] += stats[:findings_count]
            @season_totals[season_year][:replacements_count] += stats[:replacements_count]
            @season_totals[season_year][:production_grams] += stats[:production_grams]
          end
        end
      end
    end
    
    # Calculate derived values for species totals (yield and average weight)
    @species_list.each do |species|
      seasons.each do |season|
        season_year = season[:start_date].year
        species_season_stats = @species_totals[species.id][season_year]
        
        # Calculate yield per plant
        if species_season_stats[:actual_plantings] > 0
          species_season_stats[:yield_per_plant] = species_season_stats[:production_grams] / species_season_stats[:actual_plantings]
        end
        
        # Calculate average weight
        if species_season_stats[:findings_count] > 0
          species_season_stats[:avg_weight] = species_season_stats[:production_grams] / species_season_stats[:findings_count]
        end
      end
    end
    
    # Calculate derived values for season totals (yield and average weight)
    seasons.each do |season|
      season_year = season[:start_date].year
      season_stats = @season_totals[season_year]
      
      # Calculate yield per plant
      if season_stats[:actual_plantings] > 0
        season_stats[:yield_per_plant] = season_stats[:production_grams] / season_stats[:actual_plantings]
      end
      
      # Calculate average weight
      if season_stats[:findings_count] > 0
        season_stats[:avg_weight] = season_stats[:production_grams] / season_stats[:findings_count]
      end
    end
    
  end
  
  # Helper method to get findings per day for a parcel
  def get_findings_per_day(parcel_id)
    Finding.joins(location: {row: :parcel})
      .where(parcels: {id: parcel_id})
      .group("date_part('doy', finding_at)::integer / 7")
      .count
      .transform_keys { |k| (k.to_i * 7).to_s }
      .sort_by { |k, _v| k.to_i }
      .to_h
  rescue => e
    Rails.logger.error("Error getting findings per day: #{e.message}")
    return {}
  end
  
  # Update statistics with plantings data
  def update_plantings_statistics(parcel_id, age_species_stats, current_time)
    begin
      plantings_by_age_and_species = Planting.joins(location_planting: { location: { row: :parcel } })
                                          .where(parcels: {id: parcel_id})
                                          .select("plantings.*, species_id, planted_at")

      plantings_by_age_and_species.each do |planting|
        begin
          spring_age = planting&.spring_age(current_time)
          species_id = planting&.species_id
          
          if spring_age && species_id && age_species_stats[spring_age] && age_species_stats[spring_age][species_id]
            age_species_stats[spring_age][species_id][:plantings_count] += 1
          end
        rescue => e
          Rails.logger.error("Error processing planting record: #{e.message}")
          next
        end
      end
    rescue => e
      Rails.logger.error("Error querying plantings: #{e.message}")
    end
  end
  
  # Populate statistics with findings data for each season
  def populate_findings_statistics(parcel_id, age_species_stats, seasons, inoculation, current_time)
    begin
      # Query findings data with all the necessary associations and fields
      findings_data = Finding.joins(location: { row: :parcel, location_plantings: { planting: :species } })
                           .where(parcels: { id: parcel_id })
                           .select("findings.*, findings.created_at as finding_date, " +
                                   "species.id as species_id, plantings.planted_at as planting_date, " +
                                   "COALESCE(findings.finding_raw_weight, findings.finding_averaged_raw_weight, 0) as weight")

      # Process each finding and update the appropriate season stats
      findings_data.each do |finding|
        begin
          # Skip if critical data is missing
          next unless finding.finding_date && finding.planting_date && finding.species_id
          
          # Calculate spring age for this finding's planting
          planting_date = finding.planting_date.to_date
          finding_time = finding.finding_date.to_date
          spring_age = if planting_date < Date.new(finding_time.year, 1, 1)
                        finding_time.year - planting_date.year
                      else
                        0
                      end
          
          species_id = finding.species_id
          finding_date = finding.finding_date
          weight = finding.weight.to_f
          
          # Skip if we don't have this spring age or species in our data structure
          next unless spring_age && 
                     species_id && 
                     age_species_stats[spring_age] && 
                     age_species_stats[spring_age][species_id]
          
          # Determine which season this finding belongs to
          seasons.each do |season|
            season_year = season[:start_date].year
            season_range = season[:start_date]..season[:end_date]
            
            # Skip if finding is not in this season or we don't have this season in our data
            next unless season_range.cover?(finding_date) && 
                       age_species_stats[spring_age][species_id][season_year]
            
            # Update findings statistics for this season
            stats = age_species_stats[spring_age][species_id][season_year]
            
            # Increment findings count
            stats[:findings_count] += 1
            
            # Add to total production weight
            stats[:production_grams] += weight
            
            # Calculate average weight with zero check
            if stats[:findings_count] > 0
              stats[:avg_weight] = stats[:production_grams] / stats[:findings_count]
            end
            
            # Calculate yield per plant with zero check
            if stats[:actual_plantings] > 0
              stats[:yield_per_plant] = stats[:production_grams] / stats[:actual_plantings]
            end
            
            # We've found the right season, no need to check other seasons
            break
          end
        rescue => e
          Rails.logger.error("Error processing finding record: #{e.message}")
          next
        end
      end
    rescue => e
      Rails.logger.error("Error populating statistics with findings data: #{e.message}\n#{e.backtrace.join("\n")}")
    end
  end
  
  # Update statistics with replacements data
  def update_replacements_statistics(parcel_id, age_species_stats, current_time)
    begin
      replacements_data = LocationPlanting.joins(location: { row: :parcel }, planting: :species)
                                        .where(parcels: {id: parcel_id})
                                        .where("location_plantings.replaced_at IS NOT NULL") # Only count actual replacements
                                        .select("location_plantings.*, species.id as species_id, plantings.planted_at as planting_date")
      
      replacements_data.each do |replacement|
        begin
          # Calculate spring age based on planting date
          spring_age = nil
          if replacement&.planting_date.present?
            planting_date = replacement.planting_date.to_date
            spring_age = if planting_date < Date.new(current_time.year, 1, 1)
                          current_time.year - planting_date.year
                        else
                          0
                        end
          end
          
          species_id = replacement&.species_id
          if spring_age && species_id && 
             age_species_stats[spring_age] && 
             age_species_stats[spring_age][species_id]
            age_species_stats[spring_age][species_id][:replacements_count] += 1
          end
        rescue => e
          Rails.logger.error("Error processing replacement record: #{e.message}")
          next
        end
      end
    rescue => e
      Rails.logger.error("Error querying replacements: #{e.message}")
    end
  end
  

  


  private

  # Breadcrumb methods removed as they are no longer needed

  def load_filter_options
    # Create filter options for the view
    filter_options = build_filter_options
    
    @species_options = [["All Species", "all"]] + filter_options[:species]
    # Rootstock options removed - not part of this application
    # Plantation type options removed - column does not exist
    
    # Get available spring ages using the concern method
    @available_spring_ages = Parcel.available_spring_ages
  end
  


  def export_excel
    begin
      report_data = nil
      
      case @report_type
      when "weekly_summary"
        service = ExcelExport::WeeklySummaryService.new
        report_data = service.generate_weekly_summary_excel
      else
        # Default to full production report
        service = ExcelExport::ParcelService.new(@orchards, @parcel_stats)
        report_data = service.generate_parcels_excel
      end
      
      # Set headers for file download
      filename = "#{@report_type}_report_#{Time.zone.now.strftime('%Y%m%d')}.xlsx"
      response.headers["Content-Disposition"] = "attachment; filename=\"#{filename}\""
      response.headers["Content-Type"] = "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
      
      # Send the report data
      render plain: report_data
    rescue => e
      Rails.logger.error("Error exporting Excel: #{e.message}\n#{e.backtrace.join("\n")}")
      redirect_to topology_parcels_path, alert: "Error generating Excel export. Please try again."
    end
  end

  def sort_parcel_stats(parcel_stats, sort, direction)

    # Use a safe duplicate to avoid modifying the original in case of errors
    result = parcel_stats.dup
    
    begin
      # Sort the parcel stats
      result.each do |orchard_id, stats|

        # Make sure we have an array to sort
        next unless stats.is_a?(Array) && stats.any?
        
        result[orchard_id] = stats.sort_by do |stat|
          # Use safe navigation and nil handling for all sort operations
          # The negative sign is for descending order by default (we want highest values first)
          begin
            case sort
            when "name"
              # Sort by name (alphabetically) - no negative sign for strings
              stat[:name].to_s.downcase
            when "planted_at"
              # Sort by planting date - newer dates (higher) should come first
              -(stat[:planted_at].to_time.to_i rescue 0)
            when "locations_count", "locations"
              # Sort by number of locations
              -((stat[:total_locations] || 0).to_i)
            when "replacement_ratio"
              # Sort by replacement ratio
              replacement_count = (stat[:replacement_count] || 0).to_i
              total_locations = (stat[:total_locations] || 0).to_i
              # Avoid division by zero
              total_locations.positive? ? -(replacement_count.to_f / total_locations) : 0.0
            when "findings_count", "finding"
              # Sort by findings count
              current_season = stat[:current_season] || {}
              -((current_season[:findings_count] || 0).to_i)
            when "total_weight", "production"
              # Sort by total weight/production
              current_season = stat[:current_season] || {}
              -((current_season[:total_weight] || 0).to_f)
            when "average_weight", "per_tree"
              # Sort by average weight per tree
              current_season = stat[:current_season] || {}
              total_locations = (stat[:total_locations] || 0).to_i
              total_weight = (current_season[:total_weight] || 0).to_f
              # Avoid division by zero
              total_locations.positive? ? -(total_weight / total_locations) : 0.0
            when "producers_ratio", "ratio"
              # Sort by producers ratio
              current_season = stat[:current_season] || {}
              producers_count = (current_season[:producers_count] || 0).to_i
              total_locations = (stat[:total_locations] || 0).to_i
              # Avoid division by zero
              total_locations.positive? ? -(producers_count.to_f / total_locations) : 0.0
            when "production_per_planting"
              # Sort by production per planting
              current_season = stat[:current_season] || {}
              total_weight = (current_season[:total_weight] || 0).to_f
              # Avoid division by zero if planting count isn't available
              planting_count = (stat[:planting_count] || 1).to_i
              planting_count.positive? ? -(total_weight / planting_count) : 0.0
            when "production_per_producer", "per_producer"
              # Sort by production per producer
              current_season = stat[:current_season] || {}
              producers_count = (current_season[:producers_count] || 0).to_i
              total_weight = (current_season[:total_weight] || 0).to_f
              # Avoid division by zero
              producers_count.positive? ? -(total_weight / producers_count) : 0.0
            when "age"
              # Sort by spring age
              -((stat[:spring_age] || 0).to_i)
            else
              # Default to name sort if the requested sort is unknown
              stat[:name].to_s.downcase
            end
          rescue => e
            # Log the error and provide a safe default
            Rails.logger.error("Error during sort operation for #{sort}: #{e.message}")
            0
          end
        end

        # For string-based sorts that don't use the negative sign convention (name),
        # we need to reverse for desc, for numeric sorts that use the negative sign,
        # we need to reverse for asc
        if sort == "name"
          # For name sorting, reverse for descending order
          result[orchard_id] = result[orchard_id].reverse if direction == "desc"
        else
          # For all other sorts using negative values, reverse for ascending order
          result[orchard_id] = result[orchard_id].reverse if direction == "asc"
        end
      end
    
      # Return the sorted result
      result
    rescue => e
      # Log the error
      Rails.logger.error("Error in sort_parcel_stats: #{e.message}\n#{e.backtrace.join("\n")}")
      
      # Return the original unsorted stats if something went wrong
      parcel_stats
    end
  end
end
