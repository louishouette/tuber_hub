# == Schema Information
#
# Table name: nurseries
#
#  id         :bigint           not null, primary key
#  name       :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
class Nursery < ApplicationRecord
  has_many :plantings
end
