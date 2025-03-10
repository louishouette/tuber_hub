# == Schema Information
#
# Table name: prices
#
#  id                 :bigint           not null, primary key
#  applicable_at      :datetime
#  c1_price_per_kg    :decimal(, )
#  c2_price_per_kg    :decimal(, )
#  c3_price_per_kg    :decimal(, )
#  extra_price_per_kg :decimal(, )
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  channel_id         :bigint           not null
#
# Indexes
#
#  index_prices_on_channel_id  (channel_id)
#
# Foreign Keys
#
#  fk_rails_...  (channel_id => market_channels.id)
#
class Price < ApplicationRecord
  belongs_to :channel

  validates :applicable_at, presence: true
  validates :channel, presence: true
  
  # Validate that at least one price is present
  validate :at_least_one_price_present
  
  # Scope to get the latest price for each channel
  scope :latest_by_channel, -> { 
    where(id: select('DISTINCT ON (channel_id) id')
      .order('channel_id, applicable_at DESC')
      .pluck(:id))
  }
  
  private
  
  def at_least_one_price_present
    unless [extra_price_per_kg, c1_price_per_kg, c2_price_per_kg, c3_price_per_kg].any?(&:present?)
      errors.add(:base, 'At least one price must be present')
    end
  end
end
