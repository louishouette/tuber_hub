class CreateHubAdminPermissions < ActiveRecord::Migration[8.0]
  def change
    create_table :hub_admin_permissions do |t|
      t.string :namespace
      t.string :controller
      t.string :action
      t.text :description

      t.timestamps
    end
  end
end
