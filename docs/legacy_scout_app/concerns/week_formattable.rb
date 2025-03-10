module WeekFormattable
  # Format a date into a week string representation
  def format_week(date)
    begin
      return "" unless date
      
      # Get week number (ISO 8601 format, weeks start on Monday)
      week_number = date.strftime('%V').to_i
      year = date.year
      
      # Format as "Week X YYYY"
      "Week #{week_number} #{year}"
    rescue => e
      Rails.logger.error("Error formatting week: #{e.message}")
      ""
    end
  end
end
