module Analysis
  class FindingsController < ApplicationController
    def index
      @daily_findings = Finding.group_by_day(:created_at)
                             .count
                             .transform_keys { |date| date.strftime('%Y-%m-%d') }

      @cumulated_daily_findings = Finding.group_by_day(:created_at)
                                       .count
                                       .transform_keys { |date| date.strftime('%Y-%m-%d') }
                                       .transform_values
                                       .with_index { |count, i| @daily_findings.values[0..i].sum }

      # Get French holidays for the date range
      start_date = @daily_findings.keys.first
      end_date = @daily_findings.keys.last
      
      @holidays = Holidays.between(Date.parse(start_date), Date.parse(end_date), :fr).map do |holiday|
        {
          date: holiday[:date].strftime('%Y-%m-%d'),
          name: holiday[:name]
        }
      end
    end
  end
end
