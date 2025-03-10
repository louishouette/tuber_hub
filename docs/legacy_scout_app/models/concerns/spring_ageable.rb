# frozen_string_literal: true

# Concern for calculating spring age based on planted_at attribute
# 
# According to requirements:
# "Each December 1st, a parcel ages one year, provided it was planted before January 1st of the first year considered."
# Formula: If planted_at < January 1st of reference year, then reference_year - planted_year, otherwise 0
module SpringAgeable
  extend ActiveSupport::Concern

  # Calculate the spring age based on the planted_at attribute
  # @param reference_date [Time] The reference date to calculate age from (defaults to current time)
  # @return [Integer] The spring age in years
  def spring_age(reference_date = Time.zone.now)
    return 0 unless planted_at

    # Convert reference_date to Time.zone
    reference = reference_date.in_time_zone
    
    # Get December 1st of the current season
    december_first = Date.new(reference.year, 12, 1)
    
    # If we haven't reached December 1st yet, use last year's December 1st
    december_first = Date.new(reference.year - 1, 12, 1) if reference.to_date < december_first
    
    # Calculate age according to the formula:
    # IF(planted_at < DATE(YEAR(december_first),1,1), YEAR(december_first)-YEAR(planted_at), 0)
    if planted_at.to_date < Date.new(december_first.year, 1, 1)
      december_first.year - planted_at.year
    else
      0
    end
  end
  
  # Get all available spring ages for a collection of plantable items
  # @param klass [Class] The class to query (e.g., Parcel or Planting)
  # @return [Array<Integer>] Array of unique spring ages
  module ClassMethods
    def available_spring_ages(reference_date = Time.zone.now)
      # Get all planted_at dates that are not nil
      planted_dates = where.not(planted_at: nil).pluck(:planted_at)
      
      # Convert reference_date to Time.zone
      reference = reference_date.in_time_zone
      
      # Get December 1st of the current season
      current_december = Date.new(reference.year, 12, 1)
      reference = current_december.to_time.in_time_zone if reference > current_december
      
      # If we haven't reached December 1st yet, use last year's December 1st
      reference_year = if reference < Date.new(reference.year, 12, 1)
                        reference.year - 1
                      else
                        reference.year
                      end
      
      # Calculate spring age for each date and get unique values
      ages = planted_dates.map do |date|
        if date < Date.new(reference_year, 1, 1)
          reference_year - date.year
        else
          0
        end
      end
      
      # Return unique ages sorted
      ages.uniq.sort
    end
    
    # Scope to filter by spring age
    # @param age [Integer, String] The spring age to filter by
    # @return [ActiveRecord::Relation] Filtered relation
    def with_spring_age(age)
      begin
        age_int = age.to_i
        reference_date = Time.zone.now
        
        # Get December 1st of the current season
        december_first = Date.new(reference_date.year, 12, 1)
        
        # If we haven't reached December 1st yet, use last year's December 1st
        december_first = Date.new(reference_date.year - 1, 12, 1) if reference_date.to_date < december_first
        
        # Calculate January 1st of the reference year
        january_first = Date.new(december_first.year, 1, 1)
        
        # Add debug logging
        Rails.logger.info("SpringAgeable.with_spring_age called with age: #{age_int}")
        Rails.logger.info("  Reference date: #{reference_date}")
        Rails.logger.info("  December 1st: #{december_first}")
        Rails.logger.info("  January 1st: #{january_first}")
        
        # When calculating spring age, we want parcels where:
        # 1. planted_at is not null
        # 2. planted_at is before January 1st of the target year
        # 3. The difference between december_first.year and planted_at.year equals the age
        
        # Following the Excel formula: =SI(A1<DATE(ANNEE(B1);1;1);ANNEE(B1)-ANNEE(A1);0)
        # Use explicit date_part function with explicit casting to avoid ambiguity
        dec_year = december_first.year  # Get the year as an integer
        where(planted_at: ..january_first)
          .where("(? - DATE_PART('year', planted_at)) = ?", dec_year, age_int)
      rescue => e
        Rails.logger.error("Error in SpringAgeable.with_spring_age: #{e.message}\n#{e.backtrace.join('\n')}")
        # Return an empty relation if something goes wrong
        where(id: nil)
      end
    end
  end
end
