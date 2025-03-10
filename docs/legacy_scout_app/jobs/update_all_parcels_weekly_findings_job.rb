# app/jobs/update_all_parcels_weekly_findings_job.rb
#
# This job enqueues individual weekly findings update jobs for each parcel
# Used for scheduled recurring updates

class UpdateAllParcelsWeeklyFindingsJob < ApplicationJob
  queue_as :statistics

  def perform
    # Find all active parcels
    parcels = Parcel.where(archived: false)
    
    Rails.logger.info "[UpdateAllParcelsWeeklyFindingsJob] Enqueueing weekly findings update for #{parcels.count} parcels"
    
    parcels.find_each do |parcel|
      # Enqueue weekly findings update for each parcel
      UpdateParcelWeeklyFindingsJob.perform_later(parcel.id)
    end
    
    Rails.logger.info "[UpdateAllParcelsWeeklyFindingsJob] All parcel weekly findings updates have been enqueued"
  end
end
