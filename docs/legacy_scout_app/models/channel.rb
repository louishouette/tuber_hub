# == Schema Information
#
# Table name: channels
#
#  id                :bigint           not null, primary key
#  description       :text
#  last_activity_at  :datetime
#  metrics           :jsonb            not null
#  name              :string
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  market_segment_id :bigint
#
# Indexes
#
#  index_channels_on_last_activity_at   (last_activity_at)
#  index_channels_on_market_segment_id  (market_segment_id)
#
# Foreign Keys
#
#  fk_rails_...  (market_segment_id => market_segments.id)
#
class Channel < ApplicationRecord
  has_many :prices
  has_many :channel_market_places
  has_many :market_places, through: :channel_market_places

  validates :name, presence: true, uniqueness: true
end
