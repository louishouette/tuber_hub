class AddUrlToHubNotifications < ActiveRecord::Migration[8.0]
  def change
    add_column :hub_notifications, :url, :string
  end
end
