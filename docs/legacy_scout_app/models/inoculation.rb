# == Schema Information
#
# Table name: inoculations
#
#  id                     :bigint           not null, primary key
#  latin_name             :string
#  name                   :string
#  season_duration_months :integer          not null
#  season_start_month     :integer          not null
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#
class Inoculation < ApplicationRecord
  has_many :plantings
end
