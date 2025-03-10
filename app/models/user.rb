class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy

  normalizes :email_address, with: ->(e) { e.strip.downcase }

  # Role definitions
  ROLES = %w[admin moderator user].freeze

  # Validations
  validates :role, inclusion: { in: ROLES }

  # Role methods
  def admin?
    role == 'admin'
  end

  def moderator?
    role == 'moderator'
  end

  def user?
    role == 'user'
  end
end
