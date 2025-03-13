class AddRevokedByToAssignments < ActiveRecord::Migration[8.0]
  def change
    add_reference :hub_admin_role_assignments, :revoked_by, null: true, foreign_key: { to_table: :hub_admin_users }
    add_reference :hub_admin_permission_assignments, :revoked_by, null: true, foreign_key: { to_table: :hub_admin_users }
  end
end
