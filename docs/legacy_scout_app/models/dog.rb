# == Schema Information
#
# Table name: dogs
#
#  id         :bigint           not null, primary key
#  name       :string
#  color      :string
#  breed      :string
#  age        :integer
#  photo      :string
#  comment    :text
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_dogs_on_name  (name) UNIQUE
#
class Dog < ApplicationRecord
  include HasTimingStats

  has_many :findings
  has_many :harvesting_runs, through: :findings
  has_many :locations, through: :findings
  has_many :users, through: :findings, source: :harvester
  has_many :rows, through: :locations
  has_many :parcels, through: :rows
  
  validates :name, presence: true, uniqueness: true
  validates :age, numericality: { only_integer: true, greater_than_or_equal_to: 0 }, allow_nil: true

  mount_uploader :photo, PhotoUploader

  # Scopes
  scope :with_findings_count, -> { 
    select("dogs.*, COUNT(DISTINCT findings.id) as findings_count")
      .left_joins(:findings)
      .group(:id) 
  }

  def self.timing_stats_joins
    { findings: :harvesting_run }
  end

  def total_harvesting_time
    harvesting_runs.sum(:duration)
  end

  def average_harvesting_run_duration
    harvesting_runs.average(:duration)
  end

  def top_harvesters(limit = 3)
    users
      .with_timing_stats
      .order(findings_count: :desc)
      .limit(limit)
  end

  def top_parcels(limit = 5)
    parcels
      .with_timing_stats
      .order(findings_count: :desc)
      .limit(limit)
  end
end
