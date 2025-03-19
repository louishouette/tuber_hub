class Current < ActiveSupport::CurrentAttributes
  attribute :session
  attribute :farm
  delegate :user, to: :session, allow_nil: true
end
