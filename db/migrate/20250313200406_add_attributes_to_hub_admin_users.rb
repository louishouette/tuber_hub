class AddAttributesToHubAdminUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :hub_admin_users, :phone_number, :string
    add_column :hub_admin_users, :job_title, :string
    add_column :hub_admin_users, :notes, :text
    add_column :hub_admin_users, :sign_in_count, :integer
    add_column :hub_admin_users, :current_sign_in_ip, :string
  end
end
