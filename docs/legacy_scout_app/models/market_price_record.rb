# == Schema Information
#
# Table name: market_price_records
#
#  id                          :bigint           not null, primary key
#  avg_price_per_kg            :decimal(, )
#  c1_price_per_kg             :decimal(, )
#  c2_price_per_kg             :decimal(, )
#  c3_price_per_kg             :decimal(, )
#  extra_price_per_kg          :decimal(, )
#  max_price_per_kg            :decimal(, )
#  min_price_per_kg            :decimal(, )
#  published_at                :datetime
#  quantities_presented_per_kg :decimal(, )
#  quantities_sold_per_kg      :decimal(, )
#  source                      :string
#  created_at                  :datetime         not null
#  updated_at                  :datetime         not null
#  market_place_id             :bigint           not null
#
# Indexes
#
#  index_market_price_records_on_market_place_id  (market_place_id)
#
# Foreign Keys
#
#  fk_rails_...  (market_place_id => market_places.id)
#
class MarketPriceRecord < ApplicationRecord
  include Seasonable
  self.seasonable_date_field = :published_at

  belongs_to :market_place

  def self.in_season(year)
    season_start = Time.zone.local(year, SEASON_START_MONTH, 1).beginning_of_month
    season_end = Time.zone.local(year + 1, SEASON_END_MONTH, 1).end_of_month
    where(published_at: season_start..season_end)
  end

  def self.in_previous_season
    where(published_at: previous_season_start..previous_season_end)
  end

  def self.weekly_average_prices
    in_current_season
      .group(Arel.sql("DATE_TRUNC('week', market_price_records.published_at)"))
      .order(Arel.sql("DATE_TRUNC('week', market_price_records.published_at)"))
      .pluck(
        Arel.sql("DATE_TRUNC('week', market_price_records.published_at) as week"),
        Arel.sql("AVG(market_price_records.avg_price_per_kg) as avg_price")
      ).to_h
      .transform_keys { |k| k.strftime("%d %b") }
  end
  belongs_to :market_place

  validates :published_at, presence: true
  validates :source, presence: true
  validates :market_place, presence: true
  
  # Validate that at least one price is present
  validate :at_least_one_price_present
  
  # Validate price relationships when present
  validate :validate_price_relationships
  
  private
  
  def at_least_one_price_present
    unless [avg_price_per_kg, min_price_per_kg, max_price_per_kg, 
           extra_price_per_kg, c1_price_per_kg, c2_price_per_kg, 
           c3_price_per_kg].any?(&:present?)
      errors.add(:base, 'At least one price must be present')
    end
  end
  
  def validate_price_relationships
    if min_price_per_kg.present? && max_price_per_kg.present?
      if min_price_per_kg > max_price_per_kg
        errors.add(:min_price_per_kg, 'cannot be greater than max price')
      end
    end
    
    if avg_price_per_kg.present? && min_price_per_kg.present? && max_price_per_kg.present?
      if avg_price_per_kg < min_price_per_kg || avg_price_per_kg > max_price_per_kg
        errors.add(:avg_price_per_kg, 'must be between min and max prices')
      end
    end
  end
end
