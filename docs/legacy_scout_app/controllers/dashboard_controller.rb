class DashboardController < ApplicationController
  include WeeklyFindings

  def index
    @farm = Farm.find_by!(name: 'FBH')
    
    @current_date = Time.zone.today
    @current_week = @current_date.strftime('%V').to_i

    @topology_stats = {
      orchards: @farm.orchards.count,
      parcels: @farm.parcels.count,
      rows: @farm.rows.count,
      locations: @farm.locations.count
    }

    @plantation_stats = {
      plantings: @farm.plantings.count,
      actual_plantings: @farm.actual_plantings.count,
      species: @farm.plantings.joins(:species).distinct.count('species.id'),
      nurseries: @farm.plantings.joins(:nursery).distinct.count('nurseries.id'),
      inoculations: @farm.plantings.joins(:inoculation).distinct.count('inoculations.id')
    }

    # Calculate season date range (November to March)
    now = Time.zone.now
    if now.month >= 11
      # We're in Nov/Dec, season started this year
      @season_start = now.beginning_of_year + 10.months # November 1st
      @season_end = @season_start + 5.months - 1.day     # March 31st next year
    else
      if now.month <= 3
        # We're in Jan/Feb/Mar, season started last year
        @season_start = now.beginning_of_year - 2.months # November 1st last year
        @season_end = now.beginning_of_year + 3.months - 1.day # March 31st this year
      else
        # We're in Apr-Oct, show last season
        @season_start = now.beginning_of_year - 2.months # November 1st last year
        @season_end = now.beginning_of_year + 3.months - 1.day # March 31st this year
      end
    end

    season_findings = @farm.findings.where(created_at: @season_start..@season_end)
    season_runs = @farm.harvesting_sectors.joins(:harvesting_runs)
                      .where(harvesting_runs: { started_at: @season_start..@season_end })
    
    # Get season intakes
    season_intakes = Intake.where(intake_at: @season_start..@season_end)
    
    # Get current week intakes using European week (starting Monday)
    @current_date = Time.zone.today
    @current_week = @current_date.cweek  # ISO week number
    
    # Calculate the start and end of the ISO week
    # First get the current week's Monday
    @week_start = @current_date.beginning_of_week
    @week_end = @week_start.end_of_week
    
    # Debug info
    Rails.logger.info "Current date: #{@current_date}, Week: #{@current_week}"
    Rails.logger.info "Week start: #{@week_start}, Week end: #{@week_end}"
    
    @weekly_intakes = Intake.where(intake_at: @week_start.beginning_of_day..@week_end.end_of_day)
                          .order(intake_at: :desc)
    
    Rails.logger.info "Found #{@weekly_intakes.count} intakes for week #{@current_week}"
    
    # Basic stats
    total_raw_weight = season_findings.standalone.sum(:finding_raw_weight) +
                   season_runs.sum(:run_raw_weight)
    total_intake_raw_weight = season_intakes.sum(:raw_weight)
    total_intake_net_weight = season_intakes.sum(:net_weight)

    # Average weight per finding
    total_findings = season_findings.count
    avg_weight = total_findings > 0 ? total_raw_weight.to_f / total_findings : 0

    # Run statistics
    runs = HarvestingRun.where(id: season_runs.select('harvesting_runs.id'))
    
    # Average run duration (in minutes)
    total_duration = runs.where.not(duration: nil).sum(:duration).to_f * 60  # Convert to seconds
    total_runs = runs.where.not(duration: nil).count
    avg_duration = total_runs > 0 ? total_duration / total_runs : 0

    # Average runs per day (only days with 3+ runs)
    runs_by_date = runs.group("DATE(started_at AT TIME ZONE 'UTC' AT TIME ZONE 'Europe/Paris')")
                       .count
    busy_days = runs_by_date.select { |_, count| count >= 3 }
    avg_runs_per_day = if busy_days.any?
      total_runs_on_busy_days = busy_days.values.sum
      total_busy_days = busy_days.length
      total_runs_on_busy_days.to_f / total_busy_days
    else
      0
    end

    # Average time per finding (only runs with 3+ findings)
    productive_runs = runs.joins(:findings)
                         .select('harvesting_runs.*, COUNT(findings.id) as findings_count')
                         .group('harvesting_runs.id')
                         .having('COUNT(findings.id) >= 3')
    
    avg_time_per_finding = if productive_runs.any?
      total_time = productive_runs.sum { |run| run.duration.to_f * 60 }  # Convert to seconds
      total_findings = productive_runs.sum { |run| run.findings_count }
      total_time / total_findings
    else
      0
    end

    # Number of unproductive runs (less than 3 findings)
    unproductive_runs = runs.left_joins(:findings)
                           .group('harvesting_runs.id')
                           .having('COUNT(findings.id) < 3')
                           .count.length

    @stats = {
      topology: @topology_stats,
      plantation: @plantation_stats,
      season: {
        total_raw_weight: total_raw_weight,
        average_truffle_weight: avg_weight,
        total_runs: runs.count,
        total_findings: total_findings,
        average_duration: avg_duration,
        avg_runs_per_day: avg_runs_per_day,
        avg_time_per_finding: avg_time_per_finding,
        unproductive_runs: unproductive_runs,
        unproductive_runs_percentage: (unproductive_runs.to_f / runs.count) * 100
      },
      intake_stats: {
        total_intake_raw_weight: total_intake_raw_weight,
        total_intake_net_weight: total_intake_net_weight
      }
    }

    @weekly_findings = weekly_findings(@current_date)

    # Daily findings chart data
    @findings_per_day = Finding.where(created_at: @season_start..@season_end)
                              .group_by_day(:created_at)
                              .count
                              .transform_keys { |k| k.strftime("%d/%m/%y") }

    # Daily weights calculation
    @weights_per_day = @farm.findings
                           .where(created_at: @season_start..@season_end)
                           .group_by_day(:created_at)
                           .sum('COALESCE(NULLIF(finding_raw_weight, 0), finding_averaged_raw_weight)')

  end

  private

end