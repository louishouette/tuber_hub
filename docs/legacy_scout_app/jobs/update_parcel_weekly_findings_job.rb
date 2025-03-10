class UpdateParcelWeeklyFindingsJob < ApplicationJob
  queue_as :statistics

  def perform(parcel_id)
    # Check if job should run based on season
    current_month = Time.zone.now.month
    is_peak_season = (4..10).include?(current_month)
    
    # Extract job name from caller info or job_id to determine if this is a peak or off-season job
    job_name = self.job_id.to_s.downcase
    
    # For peak season job, only run during peak season months
    if job_name.include?('peak_season') && !is_peak_season
      Rails.logger.info "[UpdateParcelWeeklyFindingsJob] Skipping as it's not peak season (month: #{current_month})"
      return
    end
    
    # For off-season job, only run during off-season months
    if job_name.include?('off_season') && is_peak_season
      Rails.logger.info "[UpdateParcelWeeklyFindingsJob] Skipping as it's not off-season (month: #{current_month})"
      return
    end
    
    # If parcel_id is nil, update all parcels
    if parcel_id.nil?
      Rails.logger.info "[UpdateParcelWeeklyFindingsJob] Computing weekly findings for all parcels"
      Parcel.find_each do |parcel|
        parcel.compute_and_store_weekly_findings
      end
      Rails.logger.info "[UpdateParcelWeeklyFindingsJob] Weekly findings updated for all parcels"
      return
    end
    
    # Normal single parcel processing
    parcel = Parcel.find_by(id: parcel_id)
    return unless parcel
    
    Rails.logger.info "[UpdateParcelWeeklyFindingsJob] Computing weekly findings for parcel ##{parcel_id} (#{parcel.name})"
    parcel.compute_and_store_weekly_findings
    Rails.logger.info "[UpdateParcelWeeklyFindingsJob] Weekly findings updated for parcel ##{parcel_id}"
  end
end
