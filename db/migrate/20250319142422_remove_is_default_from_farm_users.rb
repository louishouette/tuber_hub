class RemoveIsDefaultFromFarmUsers < ActiveRecord::Migration[8.0]
  def change
    remove_column :hub_core_farm_users, :is_default, :boolean
  end
end
