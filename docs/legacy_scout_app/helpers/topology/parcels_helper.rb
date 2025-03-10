module Topology::ParcelsHelper
  def sort_direction_for(field)
    return 'none' unless params[:sort_field] == field
    params[:sort_direction] || 'asc'
  end
  
  def sort_link(field, label)
    # Determine the sort direction
    direction = if params[:sort_field] == field && params[:sort_direction] == 'asc'
                  'desc'
                else
                  'asc'
                end
    
    # Determine the icon to display
    icon = if params[:sort_field] == field
             if params[:sort_direction] == 'asc'
               '<svg class="w-3 h-3 ml-1" fill="currentColor" viewBox="0 0 20 20" xmlns="http://www.w3.org/2000/svg"><path fill-rule="evenodd" d="M14.707 12.707a1 1 0 01-1.414 0L10 9.414l-3.293 3.293a1 1 0 01-1.414-1.414l4-4a1 1 0 011.414 0l4 4a1 1 0 010 1.414z" clip-rule="evenodd"></path></svg>'
             else
               '<svg class="w-3 h-3 ml-1" fill="currentColor" viewBox="0 0 20 20" xmlns="http://www.w3.org/2000/svg"><path fill-rule="evenodd" d="M5.293 7.293a1 1 0 011.414 0L10 10.586l3.293-3.293a1 1 0 111.414 1.414l-4 4a1 1 0 01-1.414 0l-4-4a1 1 0 010-1.414z" clip-rule="evenodd"></path></svg>'
             end
           else
             '<svg class="w-3 h-3 ml-1 opacity-0 group-hover:opacity-100" fill="currentColor" viewBox="0 0 20 20" xmlns="http://www.w3.org/2000/svg"><path fill-rule="evenodd" d="M5.293 7.293a1 1 0 011.414 0L10 10.586l3.293-3.293a1 1 0 111.414 1.414l-4 4a1 1 0 01-1.414 0l-4-4a1 1 0 010-1.414z" clip-rule="evenodd"></path></svg>'
           end
    
    # Generate the link with the current filter parameters
    link_to(
      topology_parcels_path(
        params.permit(:orchard_id, :species_id, :parcel_age, :search).merge(
          sort_field: field,
          sort_direction: direction
        )
      ),
      class: "group inline-flex items-center text-sm font-medium text-gray-700 hover:text-primary-500"
    ) do
      raw("#{label} #{icon}")
    end
  end
end
