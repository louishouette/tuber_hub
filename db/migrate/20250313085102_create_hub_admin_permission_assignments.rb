class CreateHubAdminPermissionAssignments < ActiveRecord::Migration[8.0]
  def change
    create_table :hub_admin_permission_assignments do |t|
      t.references :role, null: false, foreign_key: { to_table: :hub_admin_roles }
      t.references :permission, null: false, foreign_key: { to_table: :hub_admin_permissions }
      t.references :granted_by, null: false, foreign_key: { to_table: :hub_admin_users }
      t.datetime :expires_at

      t.timestamps
    end
  end
end
