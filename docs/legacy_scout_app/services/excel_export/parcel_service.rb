  module ExcelExport
    class ParcelService < BaseService
    def initialize(orchards, parcel_stats)
      super()
      @orchards = orchards
      @parcel_stats = parcel_stats
    end
    
  def generate_parcels_excel
      begin
        worksheet = @workbook[0]
        worksheet.sheet_name = 'Parcelles'
        
      # Add headers
        headers = [
          'Truffière', 'Parcelle', 'Date Plantation', 'Âge (printemps)', 
          'Emplacements', 'Remplacements', 'Plants producteurs', 
          'Ratio producteurs', 'Production brute (g)', 'Truffes produites', 
          'Poids moyen (g)', 'Production à l\'arbre (g)', 'Production par producteur (g)'
        ]
        
      headers.each_with_index do |header, index|
          add_cell(worksheet, 0, index, header)
        end
        
      # Collect all data for sorting and processing
        all_parcels_data = collect_parcel_data
        
      # Write data
        row_index = 1
        all_parcels_data.sort_by { |data| -data[:production_per_original_tree].to_f }.each do |data|
          add_cell(worksheet, row_index, 0, data[:orchard_name])
          add_cell(worksheet, row_index, 1, data[:parcel_name])
          add_cell(worksheet, row_index, 2, data[:planted_at])
          add_cell(worksheet, row_index, 3, data[:spring_age])
          add_cell(worksheet, row_index, 4, data[:total_locations])
          
        # Replacements count
          locations_with_multiple_plantings = data[:locations_with_multiple_plantings] || 0
          replacement_display = format_value(locations_with_multiple_plantings)
          add_cell(worksheet, row_index, 5, replacement_display)
          
        # Plants producteurs
          producers_count_display = format_value(data[:producers_count])
          add_cell(worksheet, row_index, 6, producers_count_display)
          
        # Ratio producteurs
          producer_ratio_display = format_value(data[:producer_ratio], :percentage)
          add_cell(worksheet, row_index, 7, producer_ratio_display)
          
        # Production brute
          total_weight_display = format_value(data[:total_weight])
          add_cell(worksheet, row_index, 8, total_weight_display)
          
        # Truffes produites
          findings_count_display = format_value(data[:findings_count])
          add_cell(worksheet, row_index, 9, findings_count_display)
          
        # Poids moyen
          average_weight_display = format_value(data[:average_weight], :decimal)
          add_cell(worksheet, row_index, 10, average_weight_display)
          
        # Production à l'arbre
          production_per_tree_display = format_value(data[:production_per_original_tree], :decimal)
          add_cell(worksheet, row_index, 11, production_per_tree_display)
          
        # Production par producteur
          production_per_producer_display = format_value(data[:production_per_producer], :decimal)
          add_cell(worksheet, row_index, 12, production_per_producer_display)
          
        row_index += 1
        end
        
      # Add summary statistics
        add_summary_statistics(worksheet, all_parcels_data, row_index)
        
      # Create stats sheet with age and species breakdown
        add_statistics_sheet(all_parcels_data)
        
      generate
      rescue => e
        Rails.logger.error("Error generating parcels excel: #{e.message}\n#{e.backtrace.join("\n")}")
        raise
      end
    end
    
  private
  
  # Get species data for parcels with a specific spring age
  # @param parcel_ids [Array<Integer>] Array of parcel IDs to get species data for
  # @param spring_age [Integer] The spring age to filter by
  # @return [Array<Hash>] Array of species data hashes with counts, weights, and productivity
  def get_species_by_age(parcel_ids, spring_age)
    begin
      return [] if parcel_ids.empty?
      
      # Get parcels of the specified age
      parcels = Parcel.where(id: parcel_ids)
      return [] if parcels.empty?
      
      # Get all species data for these parcels
      species_data = {}
      
      # Get all original plantings (no replacements) by species for these parcels
      # We join with plantings and filter by parcels and join with findings to get production data
      plantings_by_species = LocationPlanting
        .joins(location: { row: :parcel }, planting: :species)
        .where(locations: { rows: { parcel_id: parcel_ids }})
        .select('species.id AS species_id, species.name AS species_name')
        .select('COUNT(DISTINCT location_plantings.id) AS plant_count')
        .group('species.id, species.name')
      
      # Get only original plantings (no replacements) by finding locations with only one planting
      original_plantings = LocationPlanting
        .joins(location: { row: :parcel })
        .where(locations: { rows: { parcel_id: parcel_ids }})
        .group('location_id')
        .having('COUNT(location_id) = 1')
        .count
      
      # For each species, calculate production metrics
      plantings_by_species.each do |species_planting|
        species_id = species_planting.species_id
        species_name = species_planting.species_name
        
        # Skip if we already processed this species
        next if species_data[species_id]
        
        # Get only original plantings for this species
        original_plantings_for_species = LocationPlanting
          .joins(location: { row: :parcel }, planting: :species)
          .where(locations: { rows: { parcel_id: parcel_ids }})
          .where(plantings: { species_id: species_id })
          .group('location_plantings.location_id')
          .having('COUNT(location_plantings.location_id) = 1')
          .count
        
        # Get total weight and findings count for this species in these parcels
        production_data = Finding
          .joins(location: [{ row: :parcel }, { location_plantings: { planting: :species } }])
          .where(locations: { rows: { parcel_id: parcel_ids }})
          .where(locations: { location_plantings: { plantings: { species_id: species_id }}})
          .select('SUM(COALESCE(findings.finding_raw_weight, findings.finding_averaged_raw_weight, 0)) AS total_weight, COUNT(findings.id) AS findings_count')
          .take
        
        total_weight = production_data&.total_weight.to_f || 0
        findings_count = production_data&.findings_count.to_i || 0
        
        # Store the data for this species
        species_data[species_id] = {
          species_id: species_id,
          species_name: species_name,
          plant_count: original_plantings_for_species.count,
          findings_count: findings_count,
          total_weight: total_weight
        }
      end
      
      # Convert hash to array for easier sorting
      species_data.values
    rescue => e
      Rails.logger.error("Error getting species by age #{spring_age}: #{e.message}\n#{e.backtrace.join("\n")}")
      []
    end
  end
  
  def collect_parcel_data
      all_parcels_data = []
      
    @orchards.each do |orchard|
        next unless @parcel_stats[orchard.id]
        
      @parcel_stats[orchard.id].each do |stats|
          parcel = stats[:parcel]
          
        # Skip parcels with no plantings or locations
          next if stats[:total_locations].to_i == 0
          
        # Extract or calculate all the values we need
          current_season = stats[:current_season] || {}
          
        planted_at = parcel.planted_at ? parcel.planted_at.strftime('%d/%m/%Y') : 'N/A'
          spring_age = stats[:spring_age] || 0
          total_locations = stats[:total_locations] || 0
          
        # Calculate replacements percentage
          locations_with_multiple_plantings = stats[:locations_with_multiple_plantings] || 0
          replacement_percentage = total_locations > 0 ? 
            ((locations_with_multiple_plantings.to_f / total_locations) * 100).round : 0
          
        # Count of plants that have produced
          producers_count = current_season[:producers_count] || 0
          
        # Original plantings (never replaced)
          original_plantings = total_locations - locations_with_multiple_plantings
          
        # Ratio of producers over total locations
          producer_ratio = total_locations > 0 ? 
            ((producers_count.to_f / total_locations) * 100).round : 0
          
        total_weight = current_season[:total_weight] || 0
          findings_count = current_season[:findings_count] || 0
          average_weight = findings_count > 0 ? (total_weight.to_f / findings_count).round(1) : 0
          
        # Production à l'arbre - production per original planting
          production_per_original_tree = if total_weight > 0 && original_plantings > 0
                                          (total_weight.to_f / original_plantings).round(2)
                                        else
                                          0
                                        end
          
        # Production per producer
          production_per_producer = if total_weight > 0 && producers_count > 0
                                    (total_weight.to_f / producers_count).round(2)
                                  else
                                    0
                                  end
          
        all_parcels_data << {
            orchard_name: orchard.name,
            parcel_name: parcel.canonical_name,
            parcel_id: parcel.id,
            planted_at: planted_at,
            spring_age: spring_age,
            total_locations: total_locations,
            replacement_percentage: replacement_percentage,
            producers_count: producers_count,
            producer_ratio: producer_ratio,
            total_weight: total_weight,
            findings_count: findings_count,
            average_weight: average_weight,
            production_per_original_tree: production_per_original_tree,
            production_per_producer: production_per_producer,
            # Keeping original data for calculations
            total_plantings: stats[:total_plantings] || 0,
            original_plantings: original_plantings,
            locations_with_multiple_plantings: locations_with_multiple_plantings
          }
        end
      end
      
    all_parcels_data
    end
    
  def add_summary_statistics(worksheet, all_parcels_data, row_index)
      begin
        unless all_parcels_data.empty?
          # Add totals row
          total_row = row_index + 1
          add_cell(worksheet, total_row, 0, 'TOTAL/MOYENNE')
          
        # Calculate totals
          total_parcels = all_parcels_data.size
          total_locations = all_parcels_data.sum { |d| d[:total_locations].to_i }
          total_plantings = all_parcels_data.sum { |d| d[:total_plantings].to_i }
          total_replacements = all_parcels_data.sum { |d| d[:locations_with_multiple_plantings].to_i }
          total_original_plantings = all_parcels_data.sum { |d| d[:original_plantings].to_i }
          total_producers = all_parcels_data.sum { |d| d[:producers_count].to_i }
          total_weight = all_parcels_data.sum { |d| d[:total_weight].to_f }
          total_findings = all_parcels_data.sum { |d| d[:findings_count].to_i }
          
        # Calculate averages
          avg_spring_age = total_parcels > 0 ? (all_parcels_data.sum { |d| d[:spring_age].to_i } / total_parcels.to_f).round(1) : 0
          
        # Average replacement percentage
          avg_replacement_percentage = total_locations > 0 ? ((total_replacements.to_f / total_locations) * 100).round : 0
          
        # Average producer ratio
          avg_producer_ratio = total_locations > 0 ? ((total_producers.to_f / total_locations) * 100).round : 0
          
        # Average weight
          avg_weight = total_findings > 0 ? (total_weight.to_f / total_findings).round(1) : 0
          
        # Average production per original tree
          avg_production_per_original_tree = total_original_plantings > 0 ? (total_weight.to_f / total_original_plantings).round(2) : 0
          
        # Average production per producer
          avg_production_per_producer = total_producers > 0 ? (total_weight.to_f / total_producers).round(2) : 0
          
        # Add totals to sheet using our formatting methods
          add_cell(worksheet, total_row, 3, format_value(avg_spring_age, :decimal))
          add_cell(worksheet, total_row, 4, format_value(total_locations))
          add_cell(worksheet, total_row, 5, format_value(total_replacements))
          add_cell(worksheet, total_row, 6, format_value(total_producers))
          add_cell(worksheet, total_row, 7, format_value(avg_producer_ratio, :percentage))
          add_cell(worksheet, total_row, 8, format_value(total_weight))
          add_cell(worksheet, total_row, 9, format_value(total_findings))
          add_cell(worksheet, total_row, 10, format_value(avg_weight, :decimal))
          add_cell(worksheet, total_row, 11, format_value(avg_production_per_original_tree, :decimal))
          add_cell(worksheet, total_row, 12, format_value(avg_production_per_producer, :decimal))
        end
      rescue => e
        Rails.logger.error("Error adding summary statistics: #{e.message}")
      end
    end
    
  def add_statistics_sheet(all_parcels_data)
      begin
        stats_sheet = @workbook.add_worksheet('Statistiques')
        
      # Add performance metrics title
        add_cell(stats_sheet, 2, 0, 'Productivité par âge')
        
      # Add stats headers
        stats_headers = ['Age', 'Nombre de parcelles', 'Nombre de plants', 'Nombre de truffes', 'Production (g)', 'Rendement (g/plant)', 'Poids moyen (g/truffe)']
        stats_headers.each_with_index do |header, index|
          add_cell(stats_sheet, 3, index, header)
        end
        
      # Group parcels by spring age
        parcels_by_age = {}
        all_parcels_data.each do |data|
          age = data[:spring_age].to_i
          next if age <= 0
          
        # Count all original plantings (non-replacements) for better accuracy
          original_plantings = data[:original_plantings].to_i
          
        parcels_by_age[age] ||= { 
          count: 0, 
          total_plantings: 0, 
          total_weight: 0,
          findings_count: 0,
          parcel_ids: [], 
          species_data: {}
        }
          parcels_by_age[age][:count] += 1
          parcels_by_age[age][:total_plantings] += original_plantings
          parcels_by_age[age][:total_weight] += data[:total_weight].to_f
          parcels_by_age[age][:findings_count] += data[:findings_count].to_i
          parcels_by_age[age][:parcel_ids] << data[:parcel_id] unless parcels_by_age[age][:parcel_ids].include?(data[:parcel_id])
        end
        
      # Add age-based productivity metrics with species breakdown
        current_row = 4
        
        parcels_by_age.sort.each do |age, data|
          # Calculate productivity metric with better handling for zero values
          productivity = if data[:total_weight] > 0 && data[:total_plantings] > 0
                          (data[:total_weight].to_f / data[:total_plantings]).round(2)
                        else
                          0
                        end
          
          # Calculate average weight per truffle
          avg_weight_per_truffle = if data[:total_weight] > 0 && data[:findings_count] > 0
                                  (data[:total_weight].to_f / data[:findings_count]).round(2)
                                else
                                  0
                                end

          # Add the main age row
          add_cell(stats_sheet, current_row, 0, "#{age} an#{age > 1 ? 's' : ''}")
          add_cell(stats_sheet, current_row, 1, data[:count])
          add_cell(stats_sheet, current_row, 2, format_value(data[:total_plantings]))
          add_cell(stats_sheet, current_row, 3, format_value(data[:findings_count]))
          add_cell(stats_sheet, current_row, 4, format_value(data[:total_weight]))
          add_cell(stats_sheet, current_row, 5, format_value(productivity, :decimal))
          add_cell(stats_sheet, current_row, 6, format_value(avg_weight_per_truffle, :decimal))
          
          # Get species breakdown for this age
          begin
            species_data = get_species_by_age(data[:parcel_ids], age)
            
            # Add species breakdown rows if we have data
            unless species_data.empty?
              species_data.sort_by { |s| s[:species_name] }.each_with_index do |species, i|
                current_row += 1
                
                # Calculate productivity for this species
                species_productivity = if species[:total_weight] > 0 && species[:plant_count] > 0
                                        (species[:total_weight].to_f / species[:plant_count]).round(2)
                                      else
                                        0
                                      end
                
                # Calculate average weight per truffle for this species
                species_avg_weight = if species[:total_weight] > 0 && species[:findings_count] > 0
                                      (species[:total_weight].to_f / species[:findings_count]).round(2)
                                    else
                                      0
                                    end
                
                # Add indented species row with species data
                add_cell(stats_sheet, current_row, 0, "  - #{age} an#{age > 1 ? 's' : ''}")
                add_cell(stats_sheet, current_row, 1, species[:species_name])
                add_cell(stats_sheet, current_row, 2, format_value(species[:plant_count]))
                add_cell(stats_sheet, current_row, 3, format_value(species[:findings_count]))
                add_cell(stats_sheet, current_row, 4, format_value(species[:total_weight]))
                add_cell(stats_sheet, current_row, 5, format_value(species_productivity, :decimal))
                add_cell(stats_sheet, current_row, 6, format_value(species_avg_weight, :decimal))
              end
            end
          rescue => e
            Rails.logger.error("Error getting species breakdown for age #{age}: #{e.message}")
          end
          
          # Increment for the next age group
          current_row += 1
        end
      rescue => e
        Rails.logger.error("Error adding statistics sheet: #{e.message}")
      end
    end
  end
end
