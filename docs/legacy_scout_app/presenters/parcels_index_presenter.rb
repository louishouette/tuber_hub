class ParcelsIndexPresenter
  attr_reader :orchards, :parcel_stats, :filters
  
  def initialize(orchards, parcel_stats, filters = {})
    @orchards = orchards
    @parcel_stats = parcel_stats
    @filters = filters
  end
  
  # Get total counts across all orchards
  def total_parcels_count
    parcel_stats.values.flatten.size
  end
  
  # Get total locations across all parcels
  def total_locations_count
    parcel_stats.values.flatten.sum { |stat| stat[:total_locations].to_i }
  end
  
  # Get total plantings across all parcels
  def total_plantings_count
    parcel_stats.values.flatten.sum { |stat| stat[:total_plantings].to_i }
  end
  
  # Get total producers across all parcels
  def total_producers_count
    parcel_stats.values.flatten.sum do |stat| 
      current_season = stat[:current_season] || {}
      current_season[:producers_count].to_i
    end
  end
  
  # Calculate producer ratio across all parcels
  def overall_producer_ratio
    total_locations = total_locations_count
    return 0 if total_locations == 0
    
    ((total_producers_count.to_f / total_locations) * 100).round
  end
  
  # Get total findings across all parcels
  def total_findings_count
    parcel_stats.values.flatten.sum do |stat|
      current_season = stat[:current_season] || {}
      current_season[:findings_count].to_i
    end
  end
  
  # Get total weight across all parcels
  def total_weight
    parcel_stats.values.flatten.sum do |stat|
      current_season = stat[:current_season] || {}
      current_season[:total_weight].to_f
    end
  end
  
  # Calculate average weight per finding
  def average_weight
    findings_count = total_findings_count
    return 0 if findings_count == 0
    
    (total_weight / findings_count).round(2)
  end
  
  # Calculate production per tree
  def production_per_tree
    locations_count = total_locations_count
    return 0 if locations_count == 0
    
    (total_weight / locations_count).round(2)
  end
  
  # Get total replacements count
  def total_replacements_count
    parcel_stats.values.flatten.sum { |stat| stat[:locations_with_multiple_plantings].to_i }
  end
  
  # Calculate replacement ratio
  def replacement_ratio
    total_locations = total_locations_count
    return 0 if total_locations == 0
    
    ((total_replacements_count.to_f / total_locations) * 100).round
  end
  
  # Format the active filters for display
  def active_filters_description
    filter_descriptions = []
    
    # Orchard filter
    if filters[:orchard_id].present?
      orchard = orchards.find { |o| o.id == filters[:orchard_id] }
      filter_descriptions << "Truffière: #{orchard&.name || 'Inconnue'}"
    end
    
    # Species filter
    if filters[:species_id].present?
      species = Species.find_by(id: filters[:species_id])
      filter_descriptions << "Espèce: #{species&.name || 'Inconnue'}"
    end
    
    # Rootstock filter removed - not part of this application
    
    # Age filter
    if filters[:age_min].present? || filters[:age_max].present?
      age_description = "Âge: "
      if filters[:age_min].present? && filters[:age_max].present?
        age_description += "#{filters[:age_min]} à #{filters[:age_max]} ans"
      elsif filters[:age_min].present?
        age_description += "min. #{filters[:age_min]} ans"
      else
        age_description += "max. #{filters[:age_max]} ans"
      end
      filter_descriptions << age_description
    end
    
    # Date range
    if filters[:date_from].present? || filters[:date_to].present?
      date_description = "Plantation: "
      if filters[:date_from].present? && filters[:date_to].present?
        date_description += "#{filters[:date_from].strftime('%d/%m/%Y')} à #{filters[:date_to].strftime('%d/%m/%Y')}"
      elsif filters[:date_from].present?
        date_description += "depuis #{filters[:date_from].strftime('%d/%m/%Y')}"
      else
        date_description += "jusqu'à #{filters[:date_to].strftime('%d/%m/%Y')}"
      end
      filter_descriptions << date_description
    end
    
    # Production filter
    if filters.key?(:produced)
      filter_descriptions << "Production: #{filters[:produced] ? 'Avec' : 'Sans'}"
    end
    
    # Plantation type filter removed - column does not exist
    
    # Season
    if filters[:season].present? && filters[:season] != 'current'
      filter_descriptions << "Saison: #{filters[:season]}"
    end
    
    filter_descriptions.join(" | ")
  end
end
