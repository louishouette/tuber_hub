# == Schema Information
#
# Table name: farms
#
#  id         :bigint           not null, primary key
#  name       :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_farms_on_name  (name) UNIQUE
#
class Farm < ApplicationRecord
  include HasActualPlantings
  include CanonicalNaming

  has_many :orchards

  has_many :parcels, through: :orchards
  has_many :harvesting_sectors, through: :parcels
  has_many :rows, through: :parcels
  has_many :locations, through: :rows
  has_many :plantings, through: :locations
  has_many :findings, through: :locations
  
  validates :name, presence: true, uniqueness: true
end
