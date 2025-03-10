# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.0].define(version: 2025_03_09_171716) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "dog_histories", force: :cascade do |t|
    t.text "text"
    t.boolean "availability"
    t.string "reason"
    t.bigint "dog_id", null: false
    t.bigint "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["dog_id"], name: "index_dog_histories_on_dog_id"
    t.index ["user_id"], name: "index_dog_histories_on_user_id"
  end

  create_table "dogs", force: :cascade do |t|
    t.string "name"
    t.string "gender"
    t.date "date_of_birth"
    t.string "breed"
    t.boolean "availability"
    t.string "availability_reason"
    t.bigint "domain_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["domain_id"], name: "index_dogs_on_domain_id"
  end

  create_table "dogs_users", id: false, force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "dog_id", null: false
    t.index ["dog_id", "user_id"], name: "index_dogs_users_on_dog_id_and_user_id"
    t.index ["user_id", "dog_id"], name: "index_dogs_users_on_user_id_and_dog_id"
  end

  create_table "domains", force: :cascade do |t|
    t.string "name"
    t.string "street"
    t.string "postal_code"
    t.string "city"
    t.string "country"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "codename"
    t.index ["codename"], name: "index_domains_on_codename", unique: true
  end

  create_table "domains_users", id: false, force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "domain_id", null: false
  end

  create_table "harvesting_sessions", force: :cascade do |t|
    t.string "basket_number"
    t.datetime "finished_at"
    t.text "comment"
    t.bigint "user_id", null: false
    t.bigint "dog_id"
    t.bigint "label_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["basket_number"], name: "index_harvesting_sessions_on_basket_number"
    t.index ["dog_id"], name: "index_harvesting_sessions_on_dog_id"
    t.index ["label_id"], name: "index_harvesting_sessions_on_label_id"
    t.index ["user_id"], name: "index_harvesting_sessions_on_user_id"
  end

  create_table "innoculations", force: :cascade do |t|
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_innoculations_on_name", unique: true
  end

  create_table "label_categories", force: :cascade do |t|
    t.string "name", null: false
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_label_categories_on_name", unique: true
  end

  create_table "labels", force: :cascade do |t|
    t.string "name", null: false
    t.text "description"
    t.bigint "label_category_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["label_category_id"], name: "index_labels_on_label_category_id"
    t.index ["name"], name: "index_labels_on_name", unique: true
  end

  create_table "labels_locations", id: false, force: :cascade do |t|
    t.bigint "location_id", null: false
    t.bigint "label_id", null: false
    t.index ["label_id", "location_id"], name: "index_labels_locations_on_label_id_and_location_id"
    t.index ["location_id", "label_id"], name: "index_labels_locations_on_location_id_and_label_id"
  end

  create_table "locations", force: :cascade do |t|
    t.integer "rank", null: false
    t.bigint "row_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "full_name"
    t.index ["full_name"], name: "index_locations_on_full_name", unique: true
    t.index ["row_id", "rank"], name: "index_locations_on_row_id_and_rank", unique: true
    t.index ["row_id"], name: "index_locations_on_row_id"
  end

  create_table "observable_groups", force: :cascade do |t|
    t.string "name", null: false
    t.text "description", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_observable_groups_on_name", unique: true
  end

  create_table "observables", force: :cascade do |t|
    t.string "name", null: false
    t.text "description", null: false
    t.bigint "observable_group_id", null: false
    t.boolean "is_scan_able"
    t.boolean "is_gps_able"
    t.integer "visibility_start_month"
    t.integer "visibility_duration_months"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_observables_on_name", unique: true
    t.index ["observable_group_id"], name: "index_observables_on_observable_group_id"
  end

  create_table "observations", force: :cascade do |t|
    t.bigint "observable_id", null: false
    t.bigint "label_id"
    t.string "sanitary_state"
    t.string "depth"
    t.decimal "gps_latitude", precision: 10, scale: 8
    t.decimal "gps_longitude", precision: 11, scale: 8
    t.decimal "gps_accuracy", precision: 5, scale: 2
    t.text "comment"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "harvesting_session_id"
    t.bigint "research_mission_id"
    t.bigint "dog_id"
    t.bigint "user_id", null: false
    t.index ["dog_id"], name: "index_observations_on_dog_id"
    t.index ["harvesting_session_id"], name: "index_observations_on_harvesting_session_id"
    t.index ["label_id"], name: "index_observations_on_label_id"
    t.index ["observable_id"], name: "index_observations_on_observable_id"
    t.index ["research_mission_id"], name: "index_observations_on_research_mission_id"
    t.index ["user_id"], name: "index_observations_on_user_id"
    t.check_constraint "(harvesting_session_id IS NULL OR research_mission_id IS NULL) AND NOT (harvesting_session_id IS NOT NULL AND research_mission_id IS NOT NULL)", name: "check_observation_session_exclusivity"
  end

  create_table "orchards", force: :cascade do |t|
    t.string "name", null: false
    t.bigint "domain_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "codename"
    t.string "full_name"
    t.index ["domain_id", "codename"], name: "index_orchards_on_domain_id_and_codename", unique: true
    t.index ["domain_id", "name"], name: "index_orchards_on_domain_id_and_name", unique: true
    t.index ["domain_id"], name: "index_orchards_on_domain_id"
    t.index ["full_name"], name: "index_orchards_on_full_name", unique: true
  end

  create_table "parcels", force: :cascade do |t|
    t.string "name", null: false
    t.bigint "orchard_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "full_name"
    t.index ["full_name"], name: "index_parcels_on_full_name", unique: true
    t.index ["orchard_id", "name"], name: "index_parcels_on_orchard_id_and_name", unique: true
    t.index ["orchard_id"], name: "index_parcels_on_orchard_id"
  end

  create_table "plantings", force: :cascade do |t|
    t.date "planting_date", null: false
    t.bigint "species_id", null: false
    t.bigint "innoculation_id", null: false
    t.bigint "provider_id", null: false
    t.bigint "label_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["innoculation_id"], name: "index_plantings_on_innoculation_id"
    t.index ["label_id"], name: "index_plantings_on_label_id"
    t.index ["provider_id"], name: "index_plantings_on_provider_id"
    t.index ["species_id"], name: "index_plantings_on_species_id"
  end

  create_table "providers", force: :cascade do |t|
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_providers_on_name", unique: true
  end

  create_table "research_missions", force: :cascade do |t|
    t.string "name", null: false
    t.datetime "finished_at"
    t.text "comment"
    t.bigint "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_research_missions_on_name", unique: true
    t.index ["user_id"], name: "index_research_missions_on_user_id"
  end

  create_table "rows", force: :cascade do |t|
    t.integer "rank", null: false
    t.bigint "parcel_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "full_name"
    t.index ["full_name"], name: "index_rows_on_full_name", unique: true
    t.index ["parcel_id", "rank"], name: "index_rows_on_parcel_id_and_rank", unique: true
    t.index ["parcel_id"], name: "index_rows_on_parcel_id"
  end

  create_table "sessions", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "ip_address"
    t.string "user_agent"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "species", force: :cascade do |t|
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_species_on_name", unique: true
  end

  create_table "surveying_sessions", force: :cascade do |t|
    t.string "motivation", null: false
    t.integer "basket_number"
    t.bigint "user_id", null: false
    t.bigint "dog_id"
    t.bigint "label_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "finished_at"
    t.index ["dog_id"], name: "index_surveying_sessions_on_dog_id"
    t.index ["finished_at"], name: "index_surveying_sessions_on_finished_at"
    t.index ["label_id"], name: "index_surveying_sessions_on_label_id"
    t.index ["user_id"], name: "index_surveying_sessions_on_user_id"
  end

  create_table "truffle_mappings", force: :cascade do |t|
    t.bigint "observation_id", null: false
    t.decimal "distance_cm", precision: 8, scale: 2, null: false
    t.decimal "angle_degrees", precision: 5, scale: 2, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["observation_id"], name: "index_truffle_mappings_on_observation_id", unique: true
  end

  create_table "users", force: :cascade do |t|
    t.string "email_address", null: false
    t.string "password_digest", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "role", default: 0, null: false
    t.string "first_name"
    t.string "last_name"
    t.string "handle", limit: 4
    t.index ["email_address"], name: "index_users_on_email_address", unique: true
    t.index ["handle"], name: "index_users_on_handle", unique: true
    t.index ["role"], name: "index_users_on_role"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "dog_histories", "dogs"
  add_foreign_key "dog_histories", "users"
  add_foreign_key "dogs", "domains"
  add_foreign_key "harvesting_sessions", "dogs"
  add_foreign_key "harvesting_sessions", "labels"
  add_foreign_key "harvesting_sessions", "users"
  add_foreign_key "labels", "label_categories"
  add_foreign_key "locations", "rows"
  add_foreign_key "observables", "observable_groups"
  add_foreign_key "observations", "dogs"
  add_foreign_key "observations", "harvesting_sessions"
  add_foreign_key "observations", "labels"
  add_foreign_key "observations", "observables"
  add_foreign_key "observations", "research_missions"
  add_foreign_key "observations", "users"
  add_foreign_key "orchards", "domains"
  add_foreign_key "parcels", "orchards"
  add_foreign_key "plantings", "innoculations"
  add_foreign_key "plantings", "labels"
  add_foreign_key "plantings", "providers"
  add_foreign_key "plantings", "species"
  add_foreign_key "research_missions", "users"
  add_foreign_key "rows", "parcels"
  add_foreign_key "sessions", "users"
  add_foreign_key "surveying_sessions", "dogs"
  add_foreign_key "surveying_sessions", "labels"
  add_foreign_key "surveying_sessions", "users"
  add_foreign_key "truffle_mappings", "observations"
end
