module WeekFormattable
  extend ActiveSupport::Concern

  private

  def format_week(date)
    # Use commercial format for ISO week numbers (European standard)
    # %G = ISO 8601 year number
    # %V = ISO 8601 week number (01-53)
    year = date.strftime('%G')
    week = date.strftime('%V')
    "W#{week}/#{year[-2..]}"
  end

  # Helper to parse week strings back into sortable values
  def parse_week_string(week_str)
    week_num = week_str.split('/').first[1..-1].to_i
    year = "20#{week_str.split('/').last}".to_i
    # Return as array for sorting
    [year, week_num]
  end

  def beginning_of_commercial_week(date)
    # Get to Monday of the ISO week
    date.beginning_of_week(:monday)
  end
end
