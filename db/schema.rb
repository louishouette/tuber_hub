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

ActiveRecord::Schema[8.0].define(version: 2025_03_25_085857) do
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

  create_table "hub_admin_authorization_audits", force: :cascade do |t|
    t.bigint "user_id"
    t.bigint "farm_id"
    t.string "policy_name", null: false
    t.string "query", null: false
    t.string "controller_action", null: false
    t.string "ip_address"
    t.text "user_agent"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["controller_action"], name: "index_hub_admin_authorization_audits_on_controller_action"
    t.index ["created_at"], name: "index_hub_admin_authorization_audits_on_created_at"
    t.index ["farm_id"], name: "index_hub_admin_authorization_audits_on_farm_id"
    t.index ["policy_name"], name: "index_hub_admin_authorization_audits_on_policy_name"
    t.index ["user_id"], name: "index_hub_admin_authorization_audits_on_user_id"
  end

  create_table "hub_admin_farm_users", force: :cascade do |t|
    t.bigint "farm_id", null: false
    t.bigint "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["farm_id", "user_id"], name: "idx_admin_farm_users_lookup", unique: true
    t.index ["farm_id"], name: "index_hub_admin_farm_users_on_farm_id"
    t.index ["user_id"], name: "index_hub_admin_farm_users_on_user_id"
  end

  create_table "hub_admin_farms", force: :cascade do |t|
    t.string "name", null: false
    t.string "handle", null: false
    t.text "address"
    t.text "description"
    t.string "logo"
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["handle"], name: "index_hub_admin_farms_on_handle", unique: true
    t.index ["name"], name: "index_hub_admin_farms_on_name"
  end

  create_table "hub_admin_permission_assignments", force: :cascade do |t|
    t.bigint "role_id", null: false
    t.bigint "permission_id", null: false
    t.bigint "granted_by_id", null: false
    t.datetime "expires_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "revoked_by_id"
    t.index ["expires_at"], name: "index_hub_admin_permission_assignments_on_expires_at"
    t.index ["granted_by_id"], name: "index_hub_admin_permission_assignments_on_granted_by_id"
    t.index ["permission_id"], name: "index_hub_admin_permission_assignments_on_permission_id"
    t.index ["revoked_by_id"], name: "index_hub_admin_permission_assignments_on_revoked_by_id"
    t.index ["role_id", "permission_id"], name: "idx_permission_assignments_lookup"
    t.index ["role_id"], name: "index_hub_admin_permission_assignments_on_role_id"
  end

  create_table "hub_admin_permission_audits", force: :cascade do |t|
    t.string "namespace", null: false
    t.string "controller", null: false
    t.string "action", null: false
    t.string "change_type", null: false
    t.jsonb "previous_state"
    t.bigint "permission_id"
    t.bigint "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["namespace", "controller", "action"], name: "idx_on_namespace_controller_action_a3a4846087"
    t.index ["permission_id"], name: "index_hub_admin_permission_audits_on_permission_id"
    t.index ["user_id"], name: "index_hub_admin_permission_audits_on_user_id"
  end

  create_table "hub_admin_permissions", force: :cascade do |t|
    t.string "namespace"
    t.string "controller"
    t.string "action"
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "status"
    t.datetime "discovered_at"
    t.index ["namespace", "controller", "action", "status"], name: "idx_permissions_lookup"
    t.index ["status"], name: "index_hub_admin_permissions_on_status"
  end

  create_table "hub_admin_role_assignments", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "role_id", null: false
    t.bigint "granted_by_id", null: false
    t.datetime "expires_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "revoked_by_id"
    t.bigint "farm_id"
    t.boolean "global", default: true
    t.index ["farm_id"], name: "index_hub_admin_role_assignments_on_farm_id"
    t.index ["granted_by_id"], name: "index_hub_admin_role_assignments_on_granted_by_id"
    t.index ["revoked_by_id"], name: "index_hub_admin_role_assignments_on_revoked_by_id"
    t.index ["role_id"], name: "index_hub_admin_role_assignments_on_role_id"
    t.index ["user_id", "role_id", "farm_id"], name: "idx_role_assignments_user_role_farm", unique: true
    t.index ["user_id"], name: "index_hub_admin_role_assignments_on_user_id"
  end

  create_table "hub_admin_roles", force: :cascade do |t|
    t.string "name"
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "hub_admin_users", force: :cascade do |t|
    t.string "email_address", null: false
    t.string "password_digest", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "first_name"
    t.string "last_name"
    t.boolean "active", default: true, null: false
    t.datetime "last_sign_in_at"
    t.string "phone_number"
    t.string "job_title"
    t.text "notes"
    t.integer "sign_in_count"
    t.string "current_sign_in_ip"
    t.index ["email_address"], name: "index_hub_admin_users_on_email_address", unique: true
  end

  create_table "sessions", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "ip_address"
    t.string "user_agent"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "hub_admin_authorization_audits", "hub_admin_farms", column: "farm_id"
  add_foreign_key "hub_admin_authorization_audits", "hub_admin_users", column: "user_id"
  add_foreign_key "hub_admin_farm_users", "hub_admin_farms", column: "farm_id"
  add_foreign_key "hub_admin_farm_users", "hub_admin_users", column: "user_id"
  add_foreign_key "hub_admin_permission_assignments", "hub_admin_permissions", column: "permission_id"
  add_foreign_key "hub_admin_permission_assignments", "hub_admin_roles", column: "role_id"
  add_foreign_key "hub_admin_permission_assignments", "hub_admin_users", column: "granted_by_id"
  add_foreign_key "hub_admin_permission_assignments", "hub_admin_users", column: "revoked_by_id"
  add_foreign_key "hub_admin_permission_audits", "hub_admin_permissions", column: "permission_id"
  add_foreign_key "hub_admin_permission_audits", "hub_admin_users", column: "user_id"
  add_foreign_key "hub_admin_role_assignments", "hub_admin_farms", column: "farm_id"
  add_foreign_key "hub_admin_role_assignments", "hub_admin_roles", column: "role_id"
  add_foreign_key "hub_admin_role_assignments", "hub_admin_users", column: "granted_by_id"
  add_foreign_key "hub_admin_role_assignments", "hub_admin_users", column: "revoked_by_id"
  add_foreign_key "hub_admin_role_assignments", "hub_admin_users", column: "user_id"
  add_foreign_key "sessions", "hub_admin_users", column: "user_id"
end
