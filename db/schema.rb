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

ActiveRecord::Schema[8.0].define(version: 2025_03_13_200406) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

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

  create_table "hub_admin_permissions", force: :cascade do |t|
    t.string "namespace"
    t.string "controller"
    t.string "action"
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "status"
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
    t.index ["granted_by_id"], name: "index_hub_admin_role_assignments_on_granted_by_id"
    t.index ["revoked_by_id"], name: "index_hub_admin_role_assignments_on_revoked_by_id"
    t.index ["role_id"], name: "index_hub_admin_role_assignments_on_role_id"
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

  add_foreign_key "hub_admin_permission_assignments", "hub_admin_permissions", column: "permission_id"
  add_foreign_key "hub_admin_permission_assignments", "hub_admin_roles", column: "role_id"
  add_foreign_key "hub_admin_permission_assignments", "hub_admin_users", column: "granted_by_id"
  add_foreign_key "hub_admin_permission_assignments", "hub_admin_users", column: "revoked_by_id"
  add_foreign_key "hub_admin_role_assignments", "hub_admin_roles", column: "role_id"
  add_foreign_key "hub_admin_role_assignments", "hub_admin_users", column: "granted_by_id"
  add_foreign_key "hub_admin_role_assignments", "hub_admin_users", column: "revoked_by_id"
  add_foreign_key "hub_admin_role_assignments", "hub_admin_users", column: "user_id"
  add_foreign_key "sessions", "hub_admin_users", column: "user_id"
end
