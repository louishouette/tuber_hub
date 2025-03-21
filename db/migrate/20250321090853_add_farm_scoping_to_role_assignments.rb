class AddFarmScopingToRoleAssignments < ActiveRecord::Migration[8.0]
  def change
    # Add farm_id to role_assignments to support farm-scoped roles
    add_reference :hub_admin_role_assignments, :farm, null: true, foreign_key: { to_table: :hub_admin_farms }
    
    # Add an index to the combination of user, role, and farm for faster lookups
    add_index :hub_admin_role_assignments, [:user_id, :role_id, :farm_id], unique: true, name: 'idx_role_assignments_user_role_farm'
    
    # Add a global boolean flag to indicate if this role is globally assigned (not farm-specific)
    add_column :hub_admin_role_assignments, :global, :boolean, default: true
  end
end
