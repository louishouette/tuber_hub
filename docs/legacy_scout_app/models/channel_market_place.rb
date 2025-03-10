# == Schema Information
#
# Table name: channel_market_places
#
#  id              :bigint           not null, primary key
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  channel_id      :bigint           not null
#  market_place_id :bigint           not null
#
# Indexes
#
#  index_channel_market_places_on_channel_id       (channel_id)
#  index_channel_market_places_on_market_place_id  (market_place_id)
#  index_channel_market_places_uniqueness          (channel_id,market_place_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (channel_id => market_channels.id)
#  fk_rails_...  (market_place_id => market_places.id)
#
class ChannelMarketPlace < ApplicationRecord
  belongs_to :channel, class_name: 'MarketChannel', foreign_key: 'channel_id'
  belongs_to :market_place

  validates :channel_id, uniqueness: { scope: :market_place_id }
end
