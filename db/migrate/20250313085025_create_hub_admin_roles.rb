class CreateHubAdminRoles < ActiveRecord::Migration[8.0]
  def change
    create_table :hub_admin_roles do |t|
      t.string :name
      t.text :description

      t.timestamps
    end
  end
end
