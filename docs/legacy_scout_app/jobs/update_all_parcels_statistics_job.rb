# app/jobs/update_all_parcels_statistics_job.rb
#
# This job enqueues individual update jobs for each parcel
# Used for scheduled recurring updates

class UpdateAllParcelsStatisticsJob < ApplicationJob
  queue_as :statistics

  def perform
    # Find all active parcels
    parcels = Parcel.where(archived: false)
    
    Rails.logger.info "[UpdateAllParcelsStatisticsJob] Enqueueing statistics update for #{parcels.count} parcels"
    
    parcels.find_each do |parcel|
      # Enqueue individual job for each parcel
      UpdateParcelStatisticsJob.perform_later(parcel.id)
    end
    
    Rails.logger.info "[UpdateAllParcelsStatisticsJob] All parcel statistics updates have been enqueued"
  end
end
