# == Schema Information
#
# Table name: harvesting_runs
#
#  id                   :bigint           not null, primary key
#  comment              :text
#  duration             :integer
#  run_net_weight       :integer
#  run_raw_weight       :integer
#  started_at           :datetime         not null
#  stopped_at           :datetime
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  dog_id               :bigint           not null
#  harvester_id         :bigint
#  harvesting_sector_id :bigint           not null
#  surveyor_id          :bigint           not null
#
# Indexes
#
#  index_harvesting_runs_on_dog_id                (dog_id)
#  index_harvesting_runs_on_harvester_id          (harvester_id)
#  index_harvesting_runs_on_harvesting_sector_id  (harvesting_sector_id)
#  index_harvesting_runs_on_surveyor_id           (surveyor_id)
#
# Foreign Keys
#
#  fk_rails_...  (dog_id => dogs.id)
#  fk_rails_...  (harvester_id => users.id)
#  fk_rails_...  (harvesting_sector_id => harvesting_sectors.id)
#  fk_rails_...  (surveyor_id => users.id)
#
class HarvestingRun < ApplicationRecord
  include Seasonable
  #include ActiveModel::Serialization

  belongs_to :dog
  belongs_to :surveyor, class_name: 'User'
  belongs_to :harvester, class_name: 'User', optional: true
  belongs_to :harvesting_sector
  has_many :findings
  has_many :locations, through: :findings
  has_many :rows, through: :locations
  has_many :parcels, -> { distinct }, through: :rows

  validates :started_at, presence: true
  validates :stopped_at, comparison: { greater_than: :started_at }, if: :stopped_at
  validates :duration, numericality: { only_integer: true, greater_than: 0 }, allow_nil: true
  validates :run_raw_weight, :run_net_weight, numericality: { only_integer: true, greater_than_or_equal_to: 0 }, allow_nil: true
  
  # validate :only_one_active_run_per_dog
  validate :net_weight_less_than_raw_weight, if: -> { run_raw_weight.present? && run_net_weight.present? }

  before_save :update_duration
  after_save :update_findings_averaged_weights, if: :saved_change_to_run_raw_weight?
  after_commit :schedule_weekly_findings_update, on: :update, if: :saved_change_to_stopped_at?

  # Scopes
  scope :active, -> { where(stopped_at: nil).includes(:dog, :surveyor, :harvester, :harvesting_sector) }
  scope :completed, -> { where.not(stopped_at: nil).includes(:dog, :surveyor, :harvester, :harvesting_sector) }
  scope :active_and_completed, -> { includes(:dog, :surveyor, :harvester, :harvesting_sector) }
  scope :in_season, ->(season_start, season_end) {
    where(started_at: season_start..season_end)
      .includes(:dog, :surveyor, :harvester, :harvesting_sector)
  }
  scope :recent, -> { order(started_at: :desc).limit(10) }
  scope :by_dog, ->(dog_id) { where(dog_id: dog_id) }

  def active?
    stopped_at.nil?
  end
  alias_method :active, :active?

  def duration_in_seconds
    ((stopped_at || Time.zone.now) - started_at).to_i
  end

  def duration
    return super if super || !started_at
    return nil unless stopped_at
    (duration_in_seconds / 60).round
  end

  def calculate_averaged_raw_weight
    return 0 if findings.none?
    run_raw_weight.to_d / findings.count
  end

  def update_findings_averaged_weights
    return unless run_raw_weight
    averaged_weight = calculate_averaged_raw_weight
    findings.in_batches.update_all(finding_averaged_raw_weight: averaged_weight)
  end

  private

  def update_duration
    self.duration = (duration_in_seconds / 60).round if stopped_at
  end

  def net_weight_less_than_raw_weight
    return unless run_net_weight && run_raw_weight
    if run_net_weight > run_raw_weight
      errors.add(:run_net_weight, "must be less than or equal to raw weight")
    end
  end

  def schedule_weekly_findings_update
    UpdateParcelWeeklyFindingsJob.perform_later(parcels.pluck(:id))
  end
end
