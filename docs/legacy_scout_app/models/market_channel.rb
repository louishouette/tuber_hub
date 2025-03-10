# == Schema Information
#
# Table name: market_channels
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
#  index_market_channels_on_last_activity_at   (last_activity_at)
#  index_market_channels_on_market_segment_id  (market_segment_id)
#
# Foreign Keys
#
#  fk_rails_...  (market_segment_id => market_segments.id)
#
class MarketChannel < ApplicationRecord

  # Associations
  belongs_to :market_segment

  scope :with_recent_activity, -> { where('updated_at > ?', 30.days.ago) }

  # Validations
  validates :name, presence: true

  # Scopes
  scope :with_recent_activity, -> { where('last_activity_at > ?', 30.days.ago) }

  # Methods
  def update_metrics!
    self.metrics = {
      segment_name: market_segment&.name,
      last_update: Time.zone.now
    }
    self.last_activity_at = Time.zone.now
    save!
  end
end
