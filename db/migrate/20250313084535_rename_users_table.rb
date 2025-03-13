class RenameUsersTable < ActiveRecord::Migration[8.0]
  def change
    rename_table :users, :hub_admin_users
    
    # Update foreign keys if any
    if foreign_key_exists?(:sessions, :users)
      remove_foreign_key :sessions, :users
      add_foreign_key :sessions, :hub_admin_users, column: :user_id
    end
  end
end
