module ApplicationHelper
  def format_weight(weight_in_grams)
    return "0g" if weight_in_grams.nil? || weight_in_grams.zero?
    
    if weight_in_grams >= 1000
      "#{number_with_precision(weight_in_grams / 1000.0, precision: 1)}kg"
    else
      "#{number_with_precision(weight_in_grams, precision: 0)}g"
    end
  end

  def format_performance(weight_in_grams)
    return "0g" if weight_in_grams.nil? || weight_in_grams.zero?
    
    if weight_in_grams >= 1000
      "#{number_with_precision(weight_in_grams / 1000.0, precision: 1)}kg"
    else
      "#{number_with_precision(weight_in_grams, precision: 0)}g"
    end
  end

  def format_duration_simple(seconds, include_seconds = true)
    total_minutes = (seconds / 60.0).floor
    hours = total_minutes / 60
    remaining_minutes = total_minutes % 60
    remaining_seconds = (seconds % 60).round
    
    parts = []
    parts << "#{hours}h" if hours > 0
    parts << "#{remaining_minutes}min" if remaining_minutes > 0 || (hours == 0 && remaining_seconds == 0)
    parts << "#{remaining_seconds}s" if include_seconds && remaining_seconds > 0
    
    parts.join(' ')
  end
end
