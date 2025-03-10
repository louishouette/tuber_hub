module DashboardHelper
  def format_weight(weight)
    return "0g" if weight.nil? || weight.zero?
    
    if weight >= 1000
      "#{number_with_precision(weight / 1000.0, precision: 1)}kg"
    else
      "#{number_with_precision(weight, precision: 0)}g"
    end
  end

  def format_weight_value(weight)
    return "0" if weight.nil? || weight.zero?
    
    if weight >= 1000
      number_with_precision(weight / 1000.0, precision: 1)
    else
      number_with_precision(weight, precision: 0)
    end
  end

  def format_weight_unit(weight)
    weight.to_f >= 1000 ? "kg" : "g"
  end

  def format_duration(minutes)
    return "0min" if minutes.nil? || minutes.zero?
    
    if minutes >= 60
      hours = minutes / 60
      remaining_minutes = minutes % 60
      "#{hours}h#{remaining_minutes > 0 ? " #{remaining_minutes}min" : ""}"
    else
      "#{minutes}min"
    end
  end

  def format_performance(value)
    return "0%" if value.nil? || value.zero?
    number_to_percentage(value * 100, precision: 1)
  end
end
