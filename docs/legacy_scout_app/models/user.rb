# == Schema Information
#
# Table name: users
#
#  id              :bigint           not null, primary key
#  can_harvest     :boolean          default(TRUE), not null
#  can_survey      :boolean          default(FALSE), not null
#  email_address   :string           not null
#  first_name      :string
#  is_active       :boolean          default(TRUE), not null
#  last_name       :string
#  password_digest :string           not null
#  role            :integer          default("guest"), not null
#  settings        :jsonb
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#
# Indexes
#
#  index_users_on_email_address  (email_address) UNIQUE
#
class User < ApplicationRecord
  include HasTimingStats
  has_secure_password
  has_many :sessions, dependent: :destroy
  has_many :findings, foreign_key: :harvester_id
  has_many :harvesting_runs, through: :findings
  has_many :dogs, through: :findings
  has_many :locations, through: :findings
  has_many :surveyor_findings, class_name: 'Finding', foreign_key: 'surveyor_id'
  has_many :surveyor_harvesting_runs, class_name: 'HarvestingRun', foreign_key: 'surveyor_id'

  attribute :role, :integer
  enum :role, { guest: 0, employee: 1, manager: 2, admin: 3 }, prefix: true, default: :guest

  normalizes :email_address, with: ->(e) { e.strip.downcase }
  normalizes :first_name, :last_name, with: ->(name) { name.strip }

  validates :first_name, presence: true, length: { maximum: 50 }
  validates :last_name, presence: true, length: { maximum: 50 }
  validates :role, presence: true
  validates :email_address, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  
  # Scopes
  scope :active, -> { where(is_active: true) }
  scope :can_survey, -> { where(can_survey: true) }
  scope :can_harvest, -> { where(can_harvest: true) }

  store_accessor :settings, :default_dog, :first_login

  # Callbacks
  after_initialize :set_default_values, if: :new_record?
  before_validation :set_default_password, if: :new_record?

  def name
    [first_name, last_name].compact.join(' ')
  end

  def requires_password_change?
    settings["first_login"] == true
  end

  def can_create_users?
    is_active? && can_survey?
  end

  def can_manage_users?
    role_admin?
  end
  
  def self.timing_stats_joins
    { findings: :harvesting_run }
  end

  private

  def set_default_values
    self.settings = {
      default_dog: nil,
      first_login: true
    }.merge(settings || {})
    
    self.is_active = true if is_active.nil?
    self.can_survey = false if can_survey.nil?
    self.can_harvest = true if can_harvest.nil?
    self.role ||= :guest
  end

  def set_default_password
    self.password = 'password' if password.blank?
  end
end
