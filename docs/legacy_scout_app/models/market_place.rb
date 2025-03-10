# == Schema Information
#
# Table name: market_places
#
#  id                :bigint           not null, primary key
#  country           :string
#  description       :text
#  name              :string
#  region            :string
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  market_segment_id :bigint
#
# Indexes
#
#  index_market_places_on_market_segment_id  (market_segment_id)
#
# Foreign Keys
#
#  fk_rails_...  (market_segment_id => market_segments.id)
#

class MarketPlace < ApplicationRecord
  include Seasonable

  belongs_to :market_segment, optional: true
  has_many :market_price_records, dependent: :destroy

  validates :name, presence: true
  validates :region, presence: true
  validates :country, presence: true

  scope :with_recent_activity, -> { joins(:market_price_records)
                                   .where('market_price_records.published_at > ?', 30.days.ago)
                                   .distinct }

  def available_seasons
    # Get distinct years from this market place's records
    years = market_price_records
      .distinct
      .pluck(Arel.sql('EXTRACT(YEAR FROM published_at)'))
      .compact
      .map(&:to_i)
      .uniq
      .sort
      .reverse

    # Only include years up to the current season
    current_year = self.class.current_season_start.year
    years.select { |year| year <= current_year }
  end

  def recent_activity?
    market_price_records.where('published_at > ?', 30.days.ago).exists?
  end

  def last_activity_at
    market_price_records.maximum(:published_at)
  end
end
