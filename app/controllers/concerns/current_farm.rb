module CurrentFarm
  extend ActiveSupport::Concern

  included do
    helper_method :current_farm
    before_action :set_current_farm_from_session
  end

  def current_farm
    @current_farm ||= fetch_current_farm
  end

  private

  def set_current_farm_from_session
    # Make the current farm available to Current object for views
    # but only temporarily for this request
    Current.farm = current_farm if Current.respond_to?(:farm=)
  end

  def fetch_current_farm
    # Try to find the farm from session
    if session[:current_farm_id].present?
      farm = Hub::Admin::Farm.find_by(id: session[:current_farm_id])
      return farm if farm && farm.active? && Current.user&.farms&.include?(farm)
    end

    # Try to use the user's default farm preference if available
    if Current.user&.default_farm.present?
      default_farm = Current.user.default_farm
      return default_farm if default_farm.active?
    end

    # Final fallback: first active farm the user belongs to
    Current.user&.farms&.where(active: true)&.first
  end

  # Reset current farm in session (e.g., when farm is deleted or user is removed from farm)
  def reset_current_farm
    session[:current_farm_id] = nil
    @current_farm = nil
  end
end
