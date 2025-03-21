class CreateHubAdminPermissionAudits < ActiveRecord::Migration[8.0]
  def change
    create_table :hub_admin_permission_audits do |t|
      # Permission identification
      t.string :namespace, null: false
      t.string :controller, null: false
      t.string :action, null: false
      
      # Audit information
      t.string :change_type, null: false # created, updated, archived, restored, deleted
      t.jsonb :previous_state # Storing the previous state of the permission if applicable
      
      # Foreign keys
      t.references :permission, index: true, foreign_key: { to_table: :hub_admin_permissions }
      t.references :user, index: true, foreign_key: { to_table: :hub_admin_users }
      
      t.timestamps
    end
    
    # Add an index on namespace, controller, action for quick lookups
    add_index :hub_admin_permission_audits, [:namespace, :controller, :action]
  end
end
