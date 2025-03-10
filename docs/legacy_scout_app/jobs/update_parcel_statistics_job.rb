class UpdateParcelStatisticsJob < ApplicationJob
  queue_as :default

  def perform(parcel_id = nil)
    if parcel_id
      # Update a single parcel's statistics
      parcel = Parcel.find_by(id: parcel_id)
      update_parcel_statistics(parcel) if parcel
    else
      # Update all parcels in batches to avoid memory issues
      Parcel.find_each(batch_size: 20) do |parcel|
        update_parcel_statistics(parcel)
      end
    end
  end

  private

  def update_parcel_statistics(parcel)
    Rails.logger.info("Updating statistics for parcel: #{parcel.id} - #{parcel.name}")
    
    # Calculate all statistics using the service
    stats = ParcelStatisticsService.calculate(parcel)
    
    # Update the weekly findings data in the database
    parcel.compute_and_store_weekly_findings
    
    # Cache the timestamp in the database to track when stats were last updated
    parcel.update_column(:weekly_findings_updated_at, Time.zone.now)
    
    # Return the stats hash
    stats
  end
end
