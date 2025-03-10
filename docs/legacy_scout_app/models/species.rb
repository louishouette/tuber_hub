# == Schema Information
#
# Table name: species
#
#  id          :bigint           not null, primary key
#  color_code  :string
#  comment     :text
#  description :text
#  french_name :string
#  latin_name  :string
#  name        :string
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
class Species < ApplicationRecord
  include ActiveRecord::Translation
  has_many :plantings
end
