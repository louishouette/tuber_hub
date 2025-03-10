module Analysis
  class HarvestsController < ApplicationController
    include Seasonable
    include WeekFormattable

    def index
      # Get all findings grouped by dog and week
      findings_by_dog_and_week = Finding.in_current_season
                                      .joins(:harvesting_run, :dog)
                                      .includes(:harvesting_run)  # Include harvesting_run to avoid N+1
                                      .select('dogs.id as dog_id',
                                             'dogs.name as dog_name',
                                             'findings.created_at',
                                             'findings.harvesting_run_id',
                                             'harvesting_runs.started_at',
                                             'harvesting_runs.duration')
                                      .group_by { |f| [f.dog_id, f.created_at.beginning_of_week(:monday).to_date] }

      # Get all active dogs sorted by total findings count
      all_dogs = Finding.in_current_season
                       .joins(:dog)
                       .group('dogs.name')
                       .order(Arel.sql('COUNT(*) DESC'))
                       .pluck('dogs.name')

      # Calculate average time to first finding for all dogs
      @time_to_first_finding = all_dogs.map do |dog_name|
        data_points = findings_by_dog_and_week
          .select { |key, _| findings_by_dog_and_week[key].first.dog_name == dog_name }
          .map do |key, findings|
            week = key[1]
            first_finding = findings.min_by(&:created_at)
            time_diff = ((first_finding.created_at - first_finding.started_at) / 60).round # in minutes
            [format_week(week), time_diff]  # Format week immediately
          end
          .to_h

        Rails.logger.debug "Raw data for #{dog_name}: #{data_points.inspect}"
        { name: dog_name, data: data_points }
      end

      # Get all unique weeks and sort them
      all_weeks = Finding.in_current_season
                        .pluck(Arel.sql('DISTINCT DATE(findings.created_at)'))
                        .map { |d| d.to_date.beginning_of_week(:monday) }
                        .uniq
                        .sort_by { |date| [date.strftime('%G').to_i, date.strftime('%V').to_i] }
                        .map { |date| format_week(date) }
      
      Rails.logger.debug "All sorted weeks: #{all_weeks.inspect}"

      # Ensure each dog has all weeks in sorted order
      @time_to_first_finding.each do |dog_data|
        sorted_data = all_weeks.each_with_object({}) do |week, hash|
          value = dog_data[:data][week] || 0
          hash[week] = value.zero? ? nil : value
        end
        dog_data[:data] = sorted_data
      end

      Rails.logger.debug "Time to first finding data: #{@time_to_first_finding.inspect}"

      # Calculate average time between findings using run duration / findings count
      @time_between_findings = all_dogs.map do |dog_name|
        data_points = findings_by_dog_and_week
          .select { |key, _| findings_by_dog_and_week[key].first.dog_name == dog_name }
          .map do |key, findings|
            week = key[1]
            # Group findings by harvesting run to calculate time between findings within each run
            findings_by_run = findings.group_by(&:harvesting_run_id)
            
            total_between_time = findings_by_run.sum do |_, run_findings|
              sorted_findings = run_findings.sort_by(&:created_at)
              if sorted_findings.size < 2
                0
              else
                # Sum up time differences between consecutive findings
                sorted_findings.each_cons(2).sum do |f1, f2|
                  ((f2.created_at - f1.created_at) / 60).round # Convert to minutes
                end
              end
            end
            
            total_intervals = findings_by_run.sum { |_, run_findings| [run_findings.size - 1, 0].max }
            avg_time = total_intervals > 0 ? (total_between_time / total_intervals.to_f).round : 0
            
            Rails.logger.debug "Week #{week} for #{dog_name}: total_time=#{total_between_time}, intervals=#{total_intervals}, avg=#{avg_time}"
            [format_week(week), avg_time]
          end
          .to_h

        Rails.logger.debug "Time between findings raw data for #{dog_name}: #{data_points.inspect}"
        { name: dog_name, data: data_points }
      end

      # Ensure each dog has all weeks in sorted order for time between findings
      @time_between_findings.each do |dog_data|
        sorted_data = all_weeks.each_with_object({}) do |week, hash|
          value = dog_data[:data][week] || 0
          hash[week] = value.zero? ? nil : value
        end
        dog_data[:data] = sorted_data
      end

      Rails.logger.debug "Time between findings data: #{@time_between_findings.inspect}"
    end
  end
end
