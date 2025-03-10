# == Schema Information
#
# Table name: market_segments
#
#  id          :bigint           not null, primary key
#  code        :string
#  description :text
#  name        :string
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
class MarketSegment < ApplicationRecord
  validates :name, presence: true
  validates :code, presence: true, uniqueness: true
  
  has_many :market_places
  has_many :market_channels
  
  # Define the standard segments
  TRADITIONAL_RETAIL = 'traditional_retail'
  BULK_MARKET = 'bulk_market'
  ONLINE_RETAIL = 'online_retail'
  AGENT = 'agent'
  DISTRIBUTOR = 'distributor'
  WHOLESALER = 'wholesaler'
  
  def self.segment_types
    {
      TRADITIONAL_RETAIL => 'Traditional Retail Markets',
      BULK_MARKET => 'Bulk Markets',
      ONLINE_RETAIL => 'Online Retail Marketplaces',
      AGENT => 'Agents',
      DISTRIBUTOR => 'Distributors',
      WHOLESALER => 'Wholesalers'
    }
  end
end
