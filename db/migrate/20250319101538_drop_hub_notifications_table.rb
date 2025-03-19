class DropHubNotificationsTable < ActiveRecord::Migration[8.0]
  def change
    drop_table :hub_notifications, if_exists: true
  end
end
