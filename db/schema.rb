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

ActiveRecord::Schema[8.1].define(version: 2026_04_16_210000) do
  create_table "global_habit_templates", force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.string "code", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["code"], name: "index_global_habit_templates_on_code", unique: true
  end

  create_table "habit_categories", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.string "name_normalized", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["user_id", "name_normalized"], name: "index_habit_categories_on_user_id_and_name_normalized", unique: true
    t.index ["user_id"], name: "index_habit_categories_on_user_id"
  end

  create_table "habit_completions", force: :cascade do |t|
    t.date "completed_on", null: false
    t.datetime "created_at", null: false
    t.string "status", null: false
    t.datetime "updated_at", null: false
    t.integer "user_habit_id", null: false
    t.index ["user_habit_id", "completed_on"], name: "index_habit_completions_on_user_habit_and_completed_on", unique: true
    t.index ["user_habit_id"], name: "index_habit_completions_on_user_habit_id"
  end

  create_table "sessions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "ip_address"
    t.datetime "updated_at", null: false
    t.string "user_agent"
    t.integer "user_id", null: false
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "user_habits", force: :cascade do |t|
    t.date "activation_date"
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.json "frequency_params", default: {}, null: false
    t.string "frequency_type", default: "daily", null: false
    t.integer "global_habit_template_id"
    t.integer "habit_category_id", null: false
    t.string "name", null: false
    t.string "name_normalized", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["activation_date"], name: "index_user_habits_on_activation_date"
    t.index ["frequency_type"], name: "index_user_habits_on_frequency_type"
    t.index ["global_habit_template_id"], name: "index_user_habits_on_global_habit_template_id"
    t.index ["habit_category_id"], name: "index_user_habits_on_habit_category_id"
    t.index ["user_id", "name_normalized"], name: "idx_user_habits_unique_active_name_per_user", unique: true, where: "active = 1"
    t.index ["user_id"], name: "index_user_habits_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.decimal "current_bmi", precision: 4, scale: 2
    t.decimal "current_weight_kg", precision: 5, scale: 2
    t.date "date_of_birth", null: false
    t.string "email", null: false
    t.integer "height_cm", null: false
    t.string "password_digest", null: false
    t.string "timezone", default: "", null: false
    t.datetime "updated_at", null: false
    t.boolean "verified", default: false, null: false
    t.index ["email"], name: "index_users_on_email", unique: true
  end

  create_table "weight_logs", force: :cascade do |t|
    t.decimal "bmi", precision: 4, scale: 2, null: false
    t.datetime "created_at", null: false
    t.integer "height_cm", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.decimal "weight_kg", precision: 5, scale: 2, null: false
    t.index ["user_id", "created_at"], name: "index_weight_logs_on_user_id_and_created_at"
    t.index ["user_id"], name: "index_weight_logs_on_user_id"
  end

  add_foreign_key "habit_categories", "users"
  add_foreign_key "habit_completions", "user_habits"
  add_foreign_key "sessions", "users"
  add_foreign_key "user_habits", "global_habit_templates"
  add_foreign_key "user_habits", "habit_categories"
  add_foreign_key "user_habits", "users"
  add_foreign_key "weight_logs", "users"
end
