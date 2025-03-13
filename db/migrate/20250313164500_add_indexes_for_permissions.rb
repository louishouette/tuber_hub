class AddIndexesForPermissions < ActiveRecord::Migration[8.0]
  def change
    # Add indexes to improve performance of permission checks
    add_index :hub_admin_permissions, [:namespace, :controller, :action, :status], name: 'idx_permissions_lookup'
    add_index :hub_admin_permission_assignments, [:role_id, :permission_id], name: 'idx_permission_assignments_lookup'
    add_index :hub_admin_permission_assignments, :expires_at
  end
end
