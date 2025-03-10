module HasActualPlantings
  extend ActiveSupport::Concern

  def actual_plantings
    locations
      .joins(:plantings)
      .where(<<-SQL)
        plantings.planted_at = (
          SELECT MAX(p.planted_at)
          FROM plantings p
          INNER JOIN location_plantings lp ON lp.planting_id = p.id
          WHERE lp.location_id = locations.id
        )
      SQL
      .distinct
  end
end