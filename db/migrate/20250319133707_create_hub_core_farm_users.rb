class CreateHubCoreFarmUsers < ActiveRecord::Migration[8.0]
  def change
    create_table :hub_core_farm_users do |t|
      t.references :farm, null: false, foreign_key: { to_table: :hub_core_farms }
      t.references :user, null: false, foreign_key: { to_table: :hub_admin_users }
      t.boolean :is_default, default: false, null: false

      t.timestamps
    end
    
    add_index :hub_core_farm_users, [:farm_id, :user_id], unique: true, name: 'idx_farm_users_lookup'
    add_index :hub_core_farm_users, [:user_id, :is_default], name: 'idx_user_default_farm'
  end
end
