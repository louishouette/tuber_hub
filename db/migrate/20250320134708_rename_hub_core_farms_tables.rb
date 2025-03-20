class RenameHubCoreFarmsTables < ActiveRecord::Migration[8.0]
  def up
    # Rename the farms table
    rename_table :hub_core_farms, :hub_admin_farms
    
    # Rename the farm_users join table
    rename_table :hub_core_farm_users, :hub_admin_farm_users
    
    # Update foreign key references for farm_users table
    remove_foreign_key :hub_admin_farm_users, column: :farm_id 
    add_foreign_key :hub_admin_farm_users, :hub_admin_farms, column: :farm_id
    
    # Create updated indexes directly instead of renaming (safer approach)
    if index_exists?(:hub_admin_farm_users, [:farm_id, :user_id], name: "idx_farm_users_lookup")
      remove_index :hub_admin_farm_users, name: "idx_farm_users_lookup"
      add_index :hub_admin_farm_users, [:farm_id, :user_id], name: "idx_admin_farm_users_lookup", unique: true
    end
    
    if index_exists?(:hub_admin_farm_users, :farm_id)
      remove_index :hub_admin_farm_users, :farm_id
      add_index :hub_admin_farm_users, :farm_id, name: "index_hub_admin_farm_users_on_farm_id"
    end
    
    if index_exists?(:hub_admin_farm_users, :user_id)
      remove_index :hub_admin_farm_users, :user_id
      add_index :hub_admin_farm_users, :user_id, name: "index_hub_admin_farm_users_on_user_id"
    end
    
    if index_exists?(:hub_admin_farms, :handle)
      remove_index :hub_admin_farms, :handle
      add_index :hub_admin_farms, :handle, name: "index_hub_admin_farms_on_handle", unique: true
    end
    
    if index_exists?(:hub_admin_farms, :name)
      remove_index :hub_admin_farms, :name
      add_index :hub_admin_farms, :name, name: "index_hub_admin_farms_on_name"
    end
  end
  
  def down
    # Revert updated indexes
    if index_exists?(:hub_admin_farm_users, [:farm_id, :user_id], name: "idx_admin_farm_users_lookup")
      remove_index :hub_admin_farm_users, name: "idx_admin_farm_users_lookup"
      add_index :hub_admin_farm_users, [:farm_id, :user_id], name: "idx_farm_users_lookup", unique: true
    end
    
    if index_exists?(:hub_admin_farm_users, :farm_id, name: "index_hub_admin_farm_users_on_farm_id")
      remove_index :hub_admin_farm_users, name: "index_hub_admin_farm_users_on_farm_id"
      add_index :hub_admin_farm_users, :farm_id, name: "index_hub_core_farm_users_on_farm_id"
    end
    
    if index_exists?(:hub_admin_farm_users, :user_id, name: "index_hub_admin_farm_users_on_user_id")
      remove_index :hub_admin_farm_users, name: "index_hub_admin_farm_users_on_user_id"
      add_index :hub_admin_farm_users, :user_id, name: "index_hub_core_farm_users_on_user_id"
    end
    
    if index_exists?(:hub_admin_farms, :handle, name: "index_hub_admin_farms_on_handle")
      remove_index :hub_admin_farms, name: "index_hub_admin_farms_on_handle"
      add_index :hub_admin_farms, :handle, name: "index_hub_core_farms_on_handle", unique: true
    end
    
    if index_exists?(:hub_admin_farms, :name, name: "index_hub_admin_farms_on_name")
      remove_index :hub_admin_farms, name: "index_hub_admin_farms_on_name"
      add_index :hub_admin_farms, :name, name: "index_hub_core_farms_on_name"
    end
    
    # Revert foreign key changes
    remove_foreign_key :hub_admin_farm_users, column: :farm_id
    
    # Rename tables back
    rename_table :hub_admin_farm_users, :hub_core_farm_users
    rename_table :hub_admin_farms, :hub_core_farms
    
    # Re-add the original foreign key
    add_foreign_key :hub_core_farm_users, :hub_core_farms, column: :farm_id
  end
end
