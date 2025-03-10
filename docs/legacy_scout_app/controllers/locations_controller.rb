class LocationsController < ApplicationController
  def search
    return head(:bad_request) if params[:q].blank?
    
    locations = Location.search(params[:q])
    
    respond_to do |format|
      format.json do
        render json: locations.map { |loc| {
          id: loc.id,
          name: loc.name,
          text: loc.name # for display in the dropdown
        }}
      end
    end
  end
end