class CreateHubCoreFarms < ActiveRecord::Migration[8.0]
  def change
    create_table :hub_core_farms do |t|
      t.string :name, null: false
      t.string :handle, null: false
      t.text :address
      t.text :description
      t.string :logo
      t.boolean :active, default: true, null: false

      t.timestamps
    end
    
    add_index :hub_core_farms, :handle, unique: true
    add_index :hub_core_farms, :name
  end
end
