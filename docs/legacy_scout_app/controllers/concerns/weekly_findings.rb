module WeeklyFindings
  extend ActiveSupport::Concern

  def weekly_findings(date = Time.current)
    date = date.to_date
    start_of_week = date.beginning_of_week
    end_of_week = date.end_of_week

    Finding.where(created_at: start_of_week..end_of_week)
           .group("DATE(created_at)")
           .select("DATE(created_at) as day, 
                   COUNT(*) as findings_count, 
                   SUM(finding_averaged_raw_weight) as total_weight")
           .order("DATE(created_at)")
  end
end
