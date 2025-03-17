class CreateHubNotifications < ActiveRecord::Migration[8.0]
  def change
    create_table :hub_notifications do |t|
      t.references :user, null: false, foreign_key: { to_table: :hub_admin_users }
      t.text :message
      t.string :notification_type
      t.datetime :read_at
      t.datetime :dismissed_at
      t.jsonb :metadata, default: {}
      t.datetime :displayed_at

      t.timestamps
    end
    
    add_index :hub_notifications, :notification_type
    add_index :hub_notifications, :read_at
    add_index :hub_notifications, :dismissed_at
    add_index :hub_notifications, :displayed_at
  end
end
