class ParcelPresenter
  attr_reader :parcel, :stats, :season
  
  def initialize(parcel, season: 'current')
    @parcel = parcel
    @season = season
    @stats = parcel.get_enhanced_statistics(season: season)
  end
  
  def display_name
    parcel.canonical_name
  end
  
  def display_plantation_date
    parcel.planted_at&.strftime('%d/%m/%Y') || 'N/A'
  end
  
  def display_age
    stats[:spring_age] || 'N/A'
  end
  
  def display_total_locations
    stats[:total_locations] || 0
  end
  
  def display_replacement_count
    stats[:locations_with_multiple_plantings] || 0
  end
  
  def display_replacement_percentage
    return 0 if stats[:total_locations].to_i == 0
    
    percentage = ((stats[:locations_with_multiple_plantings].to_f / stats[:total_locations]) * 100).round
    "#{percentage}%"
  end
  
  def display_producers_count
    current_season = stats[:current_season] || {}
    current_season[:producers_count] || 0
  end
  
  def display_producer_ratio
    return "0%" if stats[:total_locations].to_i == 0
    
    current_season = stats[:current_season] || {}
    producers_count = current_season[:producers_count] || 0
    
    percentage = ((producers_count.to_f / stats[:total_locations]) * 100).round
    "#{percentage}%"
  end
  
  def display_total_weight
    current_season = stats[:current_season] || {}
    total_weight = current_season[:total_weight] || 0
    
    if total_weight > 0
      total_weight.round(2)
    else
      0
    end
  end
  
  def display_findings_count
    current_season = stats[:current_season] || {}
    current_season[:findings_count] || 0
  end
  
  def display_average_weight
    current_season = stats[:current_season] || {}
    findings_count = current_season[:findings_count] || 0
    total_weight = current_season[:total_weight] || 0
    
    if findings_count > 0 && total_weight > 0
      (total_weight.to_f / findings_count).round(2)
    else
      0
    end
  end
  
  def display_production_per_tree
    # Production per original tree
    current_season = stats[:current_season] || {}
    total_weight = current_season[:total_weight] || 0
    
    # Original plantings (never replaced)
    original_plantings = stats[:total_locations].to_i - stats[:locations_with_multiple_plantings].to_i
    
    if total_weight > 0 && original_plantings > 0
      (total_weight.to_f / original_plantings).round(2)
    else
      0
    end
  end
  
  def display_production_per_producer
    current_season = stats[:current_season] || {}
    total_weight = current_season[:total_weight] || 0
    producers_count = current_season[:producers_count] || 0
    
    if total_weight > 0 && producers_count > 0
      (total_weight.to_f / producers_count).round(2)
    else
      0
    end
  end
  
  def display_species_breakdown
    species_breakdown = stats[:species_breakdown] || {}
    
    # Ensure the breakdown is formatted for display
    species_breakdown.transform_values do |value|
      {
        count: value[:count] || 0,
        percentage: value[:percentage] ? "#{value[:percentage].round}%" : "0%"
      }
    end
  end
  
  # Rootstock breakdown removed - not part of this application
  def display_rootstock_breakdown
    {}
  end
  
  # Get weekly findings data
  def display_weekly_findings
    return {} unless stats[:weekly_findings].present?
    
    stats[:weekly_findings].transform_values do |data|
      {
        count: data[:count] || 0,
        production: number_to_human(data[:production].to_f, precision: 2, units: { unit: "g", thousand: "kg" })
      }
    end
  end
  
  # Format a week number into a readable string
  def format_week(week_number)
    begin
      # Try to parse as a date
      date = Time.zone.parse(week_number.to_s)
      "Week #{date.strftime('%U')} (#{date.strftime('%b %d')})"
    rescue
      # If it's just a week number
      "Week #{week_number}"
    end
  end

  # Helper to format numbers with units
  def number_to_human(number, options = {})
    return "0" if number.nil? || number == 0
    
    units = options[:units] || { unit: "g", thousand: "kg" }
    precision = options[:precision] || 2
    
    if number >= 1000
      "#{(number.to_f / 1000).round(precision)} #{units[:thousand]}"
    else
      "#{number.round(precision)} #{units[:unit]}"
    end
  end
  
  # Cache key for this presenter
  def cache_key
    "parcel_presenter/#{parcel.id}-#{parcel.updated_at.to_i}-#{season}"
  end
end
