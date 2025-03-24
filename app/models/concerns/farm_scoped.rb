# frozen_string_literal: true

# This concern adds farm scoping functionality to models
# It should be included in models that belong to a farm
module FarmScoped
  extend ActiveSupport::Concern

  included do
    belongs_to :farm, class_name: 'Hub::Admin::Farm', optional: false
    
    # Default scope to ensure farm-specific data isolation
    scope :for_farm, ->(farm_id) { where(farm_id: farm_id) }
    
    # Class method to get records for the current farm
    def self.for_current_farm
      # Use Current.farm as the source of truth for the current farm
      return none unless Current.farm.present?
      
      for_farm(Current.farm.id)
    end
  end
  
  # Instance methods
  
  # Check if record belongs to the specified farm
  def belongs_to_farm?(farm_id)
    self.farm_id == farm_id
  end
  
  # Check if record belongs to the current farm
  def belongs_to_current_farm?
    # Use Current.farm as the source of truth for the current farm
    Current.farm.present? && belongs_to_farm?(Current.farm.id)
  end
end
