class AddDiscoveredAtToHubAdminPermissions < ActiveRecord::Migration[8.0]
  def change
    add_column :hub_admin_permissions, :discovered_at, :datetime
  end
end
