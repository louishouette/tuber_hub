class CreateHubAdminAuthorizationAudits < ActiveRecord::Migration[8.0]
  def change
    create_table :hub_admin_authorization_audits do |t|
      # References to users and farms, both optional
      t.references :user, foreign_key: { to_table: :hub_admin_users }, null: true
      t.references :farm, foreign_key: { to_table: :hub_admin_farms }, null: true
      
      # Authorization details
      t.string :policy_name, null: false
      t.string :query, null: false
      t.string :controller_action, null: false
      
      # Additional context for security analysis
      t.string :ip_address
      t.text :user_agent
      
      # Add indexes for commonly queried fields
      t.index [:policy_name]
      t.index [:controller_action]
      t.index [:created_at]
      
      t.timestamps
    end
  end
end
