# == Schema Information
#
# Table name: hub_notifications
#
#  id                :bigint           not null, primary key
#  dismissed_at      :datetime
#  displayed_at      :datetime
#  message           :text
#  metadata          :jsonb
#  notification_type :string
#  read_at           :datetime
#  url               :string
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  user_id           :bigint           not null
#
# Indexes
#
#  index_hub_notifications_on_dismissed_at       (dismissed_at)
#  index_hub_notifications_on_displayed_at       (displayed_at)
#  index_hub_notifications_on_notification_type  (notification_type)
#  index_hub_notifications_on_read_at            (read_at)
#  index_hub_notifications_on_user_id            (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (user_id => hub_admin_users.id)
#
class Hub::Notification < ApplicationRecord
  belongs_to :user, class_name: 'Hub::Admin::User'
  
  VALID_TYPES = %w[info success warning error].freeze
  
  validates :notification_type, inclusion: { in: VALID_TYPES }
  
  scope :unread, -> { where(read_at: nil) }
  scope :undismissed, -> { where(dismissed_at: nil) }
  scope :recent, -> { order(created_at: :desc) }
  scope :not_displayed, -> { where(displayed_at: nil) }
  scope :for_user, ->(user_id) { where(user_id: user_id) }
  
  # Scopes by type
  scope :info, -> { where(notification_type: 'info') }
  scope :success, -> { where(notification_type: 'success') }
  scope :warning, -> { where(notification_type: 'warning') }
  scope :error, -> { where(notification_type: 'error') }
  
  def mark_as_read!
    update!(read_at: Time.zone.now) if read_at.nil?
  end
  
  def dismiss!
    update!(dismissed_at: Time.zone.now) if dismissed_at.nil?
  end
  
  def mark_as_displayed!
    update!(displayed_at: Time.zone.now) if displayed_at.nil?
  end
end
