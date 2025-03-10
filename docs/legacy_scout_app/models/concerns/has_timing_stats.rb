module HasTimingStats
  extend ActiveSupport::Concern

  included do
    scope :with_timing_stats, -> {
      first_findings_subquery = Finding
        .joins(:harvesting_run)
        .select('findings.harvesting_run_id, MIN(findings.created_at) as first_finding_time, harvesting_runs.started_at')
        .where('findings.created_at >= harvesting_runs.started_at')  
        .group('findings.harvesting_run_id, harvesting_runs.started_at')

      run_findings_subquery = Finding
        .joins(:harvesting_run)
        .select('findings.harvesting_run_id, COUNT(*) as findings_count, harvesting_runs.duration')
        .group('findings.harvesting_run_id, harvesting_runs.duration')
        .having('COUNT(*) > 1')

      joins(timing_stats_joins)
      .joins(
        "LEFT JOIN (#{first_findings_subquery.to_sql}) first_findings ON first_findings.harvesting_run_id = findings.harvesting_run_id"
      )
      .joins(
        "LEFT JOIN (#{run_findings_subquery.to_sql}) run_findings ON run_findings.harvesting_run_id = findings.harvesting_run_id"
      )
      .select(
        "#{table_name}.*",
        "COUNT(DISTINCT findings.id) as findings_count",
        "ROUND(CAST(AVG(EXTRACT(EPOCH FROM (first_findings.first_finding_time - first_findings.started_at))) / 60.0 AS NUMERIC), 2) as avg_time_to_first_finding",
        "ROUND(CAST(AVG(
          CASE WHEN run_findings.findings_count > 1 
            THEN run_findings.duration::float / NULLIF(run_findings.findings_count - 1, 0)
            ELSE NULL 
          END
        ) AS NUMERIC), 2) as avg_time_between_findings",
        "SUM(run_findings.duration) as total_harvesting_time"
      )
      .group(:id)
    }
  end

  def total_findings_count
    findings.count
  end

  def avg_time_to_first_finding
    first_findings = findings
      .joins(:harvesting_run)
      .select('harvesting_runs.id, harvesting_runs.started_at, MIN(findings.created_at) as first_finding')
      .where('findings.created_at >= harvesting_runs.started_at')  
      .group('harvesting_runs.id, harvesting_runs.started_at')

    Finding.connection.select_value(
      "SELECT ROUND(CAST(AVG(EXTRACT(EPOCH FROM (first_finding - started_at))) / 60.0 AS NUMERIC), 2)
       FROM (#{first_findings.to_sql}) AS first_findings"
    )
  end

  def avg_time_between_findings
    run_stats = findings
      .joins(:harvesting_run)
      .select(
        'harvesting_runs.id',
        'harvesting_runs.duration',
        'COUNT(*) as findings_count'
      )
      .group('harvesting_runs.id, harvesting_runs.duration')
      .having('COUNT(*) > 1')

    Finding.connection.select_value(
      "SELECT ROUND(CAST(AVG(
        CASE WHEN findings_count > 1 
          THEN duration::float / NULLIF(findings_count - 1, 0)
          ELSE NULL 
        END
      ) AS NUMERIC), 2)
      FROM (#{run_stats.to_sql}) AS run_stats"
    )
  end
end
