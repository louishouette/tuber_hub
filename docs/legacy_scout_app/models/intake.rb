# == Schema Information
#
# Table name: intakes
#
#  id                :bigint           not null, primary key
#  comment           :text
#  edible_number     :integer
#  edible_weight     :decimal(10, 2)
#  intake_at         :datetime         not null
#  net_number        :integer
#  net_weight        :decimal(10, 2)
#  non_edible_number :integer
#  non_edible_weight :decimal(10, 2)
#  raw_number        :integer
#  raw_weight        :decimal(10, 2)   not null
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  operator_id       :bigint           not null
#
# Indexes
#
#  index_intakes_on_operator_id  (operator_id)
#  index_intakes_on_intake_at    (intake_at) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (operator_id => users.id)
#
class Intake < ApplicationRecord
  belongs_to :operator, class_name: 'User'
  
  validates :intake_at, presence: true
  validates :raw_number, :raw_weight, :net_weight, :edible_weight, :non_edible_weight,
            numericality: { greater_than_or_equal_to: 0 }, allow_nil: true

  def intake_at=(value)
    if value.is_a?(String) && value.match?(%r{\A\d{2}/\d{2}/\d{4}\z})
      day, month, year = value.split('/')
      super Date.new(year.to_i, month.to_i, day.to_i)
    else
      super(value)
    end
  rescue Date::Error
    super(value)
  end
end
