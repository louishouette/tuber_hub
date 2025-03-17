class NotificationChannel < ApplicationCable::Channel
  def subscribed
    # Stream notifications specific to the current user
    stream_from "notifications:#{current_user.id}"
  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
    stop_all_streams
  end
end
