class AddStatusToHubAdminPermissions < ActiveRecord::Migration[8.0]
  def change
    add_column :hub_admin_permissions, :status, :string
    add_index :hub_admin_permissions, :status
    
    # Set all existing permissions to active status
    execute <<-SQL
      UPDATE hub_admin_permissions
      SET status = 'active'
      WHERE status IS NULL
    SQL
  end
end
