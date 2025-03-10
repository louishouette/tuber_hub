json.extract! intake, :id, :intakeable_id, :intakeable_type, :operator_id, :raw_number, :raw_weight, :net_number, :net_weight, :edible_number, :edible_weight, :non_edible_number, :non_edible_weight, :comment, :intake_at, :created_at, :updated_at
json.url intake_url(intake, format: :json)
