# frozen_string_literal: true

# Concern for controllers that require a farm to be selected
module FarmSelection
  extend ActiveSupport::Concern

  included do
    before_action :require_farm_selection
  end

  private

  # Redirects to the farms page if no farm is selected
  # Uses Current.farm to check if a farm is selected
  def require_farm_selection
    redirect_to hub_farms_path, alert: "Please select a farm to continue." unless Current.farm.present?
  end
end
