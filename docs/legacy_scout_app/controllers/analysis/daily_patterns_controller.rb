module Analysis
  class DailyPatternsController < ApplicationController
    def index
      @findings_by_hour = Finding.group_by_hour_of_day(:created_at, format: "%H:00")
                                .count
                                .select { |hour, _| hour.to_i >= 8 && hour.to_i <= 18 }
    end
  end
end
