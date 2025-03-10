# == Schema Information
#
# Table name: intake_findings
#
#  id         :bigint           not null, primary key
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  finding_id :bigint           not null
#  intake_id  :bigint           not null
#
# Indexes
#
#  index_intake_findings_on_finding_id                (finding_id)
#  index_intake_findings_on_intake_id                 (intake_id)
#  index_intake_findings_on_intake_id_and_finding_id  (intake_id,finding_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (finding_id => findings.id)
#  fk_rails_...  (intake_id => intakes.id)
#
class IntakeFinding < ApplicationRecord
  belongs_to :intake
  belongs_to :finding

  validates :finding_id, uniqueness: { message: "has already been assigned to another intake" }
end
