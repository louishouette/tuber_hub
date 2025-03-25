class CreateHubAdminUserPreferences < ActiveRecord::Migration[8.0]
  def change
    create_table :hub_admin_user_preferences do |t|
      t.references :user, null: false, foreign_key: { to_table: :hub_admin_users }
      t.string :key, null: false
      t.text :value

      t.timestamps
    end
    
    add_index :hub_admin_user_preferences, [:user_id, :key], unique: true, name: 'index_user_preferences_on_user_id_and_key'
  end
end
