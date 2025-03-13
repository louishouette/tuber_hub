class AddActiveToHubAdminUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :hub_admin_users, :active, :boolean, default: true, null: false
  end
end
