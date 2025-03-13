class AddLastSignInAtToHubAdminUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :hub_admin_users, :last_sign_in_at, :datetime
  end
end
