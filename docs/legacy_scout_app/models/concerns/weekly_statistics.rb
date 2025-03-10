module WeeklyStatistics
  extend ActiveSupport::Concern
  
  included do
    scope :in_current_season, -> {
      where(created_at: current_season_range)
    }
    
    scope :weekly_stats, -> {
      group_by_week(:created_at, week_start: :monday)
    }
  end
  
  class_methods do
    def current_season_range
      # Define what constitutes the current season
      # For example, from July 1st to June 30th of the next year
      current_year = Time.zone.now.year
      current_month = Time.zone.now.month
      
      if current_month >= 7
        # We're in the second half of the calendar year, so the season starts this year
        season_start = Time.zone.local(current_year, 7, 1).beginning_of_day
        season_end = Time.zone.local(current_year + 1, 6, 30).end_of_day
      else
        # We're in the first half of the calendar year, so the season started last year
        season_start = Time.zone.local(current_year - 1, 7, 1).beginning_of_day
        season_end = Time.zone.local(current_year, 6, 30).end_of_day
      end
      
      season_start..season_end
    end
  end
end
