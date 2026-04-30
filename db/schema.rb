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

ActiveRecord::Schema[8.1].define(version: 2026_04_29_233000) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "active_storage_attachments", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "record_id", null: false
    t.string "record_type", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.string "content_type"
    t.datetime "created_at", null: false
    t.string "filename", null: false
    t.string "key", null: false
    t.text "metadata"
    t.string "service_name", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "catalog_listing_facets", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "difficulty_level", limit: 32
    t.integer "duration_weeks_max"
    t.integer "duration_weeks_min"
    t.string "goal_phrase", limit: 255
    t.integer "listable_id", null: false
    t.string "listable_type", null: false
    t.string "normalized_tags", limit: 500
    t.datetime "updated_at", null: false
    t.index ["listable_type", "listable_id"], name: "index_catalog_listing_facets_on_listable", unique: true
  end

  create_table "dishes", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "instructions"
    t.string "meal_type", default: "desayuno", null: false
    t.string "name", null: false
    t.boolean "publicly_shareable", default: false, null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["user_id", "meal_type"], name: "index_dishes_on_user_id_and_meal_type"
    t.index ["user_id"], name: "index_dishes_on_user_id"
  end

  create_table "exercise_routine_assignments", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "end_week", null: false
    t.bigint "exercise_routine_id", null: false
    t.integer "start_week", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["exercise_routine_id"], name: "index_exercise_routine_assignments_on_exercise_routine_id"
    t.index ["user_id", "start_week", "end_week"], name: "index_exercise_routine_assignments_on_user_and_range"
    t.index ["user_id"], name: "index_exercise_routine_assignments_on_user_id"
    t.check_constraint "end_week >= start_week", name: "exercise_routine_assignments_end_gte_start"
    t.check_constraint "start_week >= 1", name: "exercise_routine_assignments_start_week_gte_one"
  end

  create_table "exercise_routine_lines", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "exercise_routine_id", null: false
    t.string "label", limit: 500, null: false
    t.text "notes"
    t.integer "position", null: false
    t.datetime "updated_at", null: false
    t.integer "weekday", null: false
    t.index ["exercise_routine_id", "weekday", "position"], name: "index_exercise_routine_lines_on_routine_weekday_position", unique: true
    t.index ["exercise_routine_id"], name: "index_exercise_routine_lines_on_exercise_routine_id"
  end

  create_table "exercise_routines", force: :cascade do |t|
    t.integer "adoption_catalog_origin_id"
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.string "name_normalized", null: false
    t.integer "public_catalog_adoptions_count", default: 0, null: false
    t.integer "public_catalog_distinct_adopters_count", default: 0, null: false
    t.boolean "publicly_shareable", default: false, null: false
    t.bigint "source_exercise_routine_id"
    t.string "source_sync_fingerprint"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["source_exercise_routine_id"], name: "index_exercise_routines_on_source_exercise_routine_id"
    t.index ["user_id", "name_normalized"], name: "index_exercise_routines_on_user_and_name_normalized", unique: true
    t.index ["user_id", "source_exercise_routine_id"], name: "index_exercise_routines_adoption_unique_per_user_and_source", unique: true, where: "(source_exercise_routine_id IS NOT NULL)"
    t.index ["user_id"], name: "index_exercise_routines_on_user_id"
  end

  create_table "global_habit_templates", force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.string "code", null: false
    t.datetime "created_at", null: false
    t.integer "suggested_daily_target", default: 1, null: false
    t.string "suggested_habit_metric_kind", default: "none", null: false
    t.datetime "updated_at", null: false
    t.index ["code"], name: "index_global_habit_templates_on_code", unique: true
  end

  create_table "habit_categories", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.string "name_normalized", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["user_id", "name_normalized"], name: "index_habit_categories_on_user_id_and_name_normalized", unique: true
    t.index ["user_id"], name: "index_habit_categories_on_user_id"
  end

  create_table "habit_completions", force: :cascade do |t|
    t.date "completed_on", null: false
    t.datetime "created_at", null: false
    t.integer "day_progress", default: 0, null: false
    t.boolean "marked_failed_by_user", default: false, null: false
    t.string "status", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_habit_id", null: false
    t.index ["user_habit_id", "completed_on"], name: "index_habit_completions_on_user_habit_and_completed_on", unique: true
    t.index ["user_habit_id"], name: "index_habit_completions_on_user_habit_id"
  end

  create_table "habit_reminder_events", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.date "local_date", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_habit_id", null: false
    t.bigint "user_id", null: false
    t.index ["user_habit_id"], name: "index_habit_reminder_events_on_user_habit_id"
    t.index ["user_id", "user_habit_id", "local_date"], name: "index_habit_reminder_events_uniqueness", unique: true
    t.index ["user_id"], name: "index_habit_reminder_events_on_user_id"
  end

  create_table "menu_entries", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "dish_id"
    t.text "freeform_text"
    t.string "meal_type", null: false
    t.bigint "menu_id", null: false
    t.datetime "updated_at", null: false
    t.integer "weekday", null: false
    t.index ["dish_id"], name: "index_menu_entries_on_dish_id"
    t.index ["menu_id", "weekday", "meal_type"], name: "index_menu_entries_on_menu_weekday_meal_type", unique: true
    t.index ["menu_id"], name: "index_menu_entries_on_menu_id"
  end

  create_table "menus", force: :cascade do |t|
    t.integer "adoption_catalog_origin_id"
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.string "name_normalized", null: false
    t.integer "public_catalog_adoptions_count", default: 0, null: false
    t.integer "public_catalog_distinct_adopters_count", default: 0, null: false
    t.boolean "publicly_shareable", default: false, null: false
    t.bigint "source_menu_id"
    t.string "source_sync_fingerprint"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["source_menu_id"], name: "index_menus_on_source_menu_id"
    t.index ["user_id", "name_normalized"], name: "index_menus_on_user_id_and_name_normalized", unique: true
    t.index ["user_id", "source_menu_id"], name: "index_menus_adoption_unique_per_user_and_source", unique: true, where: "(source_menu_id IS NOT NULL)"
    t.index ["user_id"], name: "index_menus_on_user_id"
  end

  create_table "phase_assignments", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "end_week", null: false
    t.bigint "menu_id", null: false
    t.integer "start_week", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["menu_id"], name: "index_phase_assignments_on_menu_id"
    t.index ["user_id", "start_week", "end_week"], name: "index_phase_assignments_on_user_and_range"
    t.index ["user_id"], name: "index_phase_assignments_on_user_id"
    t.check_constraint "end_week >= start_week", name: "phase_assignments_end_gte_start"
    t.check_constraint "start_week >= 1", name: "phase_assignments_start_week_gte_one"
  end

  create_table "phase_menu_blocks", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "end_week", null: false
    t.bigint "menu_id", null: false
    t.bigint "phase_id", null: false
    t.integer "start_week", null: false
    t.datetime "updated_at", null: false
    t.index ["phase_id", "start_week", "end_week"], name: "index_phase_menu_blocks_on_phase_and_range"
    t.index ["phase_id"], name: "index_phase_menu_blocks_on_phase_id"
    t.check_constraint "end_week >= start_week", name: "phase_menu_blocks_end_gte_start"
    t.check_constraint "start_week >= 1", name: "phase_menu_blocks_start_week_gte_one"
  end

  create_table "phase_reminder_events", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "kind", null: false
    t.date "local_date", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["user_id", "kind", "local_date"], name: "index_phase_reminder_events_uniqueness", unique: true
    t.index ["user_id"], name: "index_phase_reminder_events_on_user_id"
  end

  create_table "phase_routine_blocks", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "end_week", null: false
    t.bigint "exercise_routine_id", null: false
    t.bigint "phase_id", null: false
    t.integer "start_week", null: false
    t.datetime "updated_at", null: false
    t.index ["phase_id", "start_week", "end_week"], name: "index_phase_routine_blocks_on_phase_and_range"
    t.index ["phase_id"], name: "index_phase_routine_blocks_on_phase_id"
    t.check_constraint "end_week >= start_week", name: "phase_routine_blocks_end_gte_start"
    t.check_constraint "start_week >= 1", name: "phase_routine_blocks_start_week_gte_one"
  end

  create_table "phases", force: :cascade do |t|
    t.bigint "adoption_catalog_origin_id"
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.string "name_normalized", null: false
    t.integer "public_catalog_adoptions_count", default: 0, null: false
    t.integer "public_catalog_distinct_adopters_count", default: 0, null: false
    t.boolean "publicly_shareable", default: false, null: false
    t.bigint "source_phase_id"
    t.string "source_sync_fingerprint"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.integer "weeks_total", null: false
    t.index ["source_phase_id"], name: "index_phases_on_source_phase_id"
    t.index ["user_id", "name_normalized"], name: "index_phases_on_user_and_name_normalized", unique: true
    t.index ["user_id", "source_phase_id"], name: "index_phases_adoption_unique_per_user_and_source", unique: true, where: "(source_phase_id IS NOT NULL)"
    t.index ["user_id"], name: "index_phases_on_user_id"
    t.check_constraint "weeks_total >= 1", name: "phases_weeks_total_gte_one"
  end

  create_table "plan_assignments", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "end_week", null: false
    t.bigint "exercise_routine_id", null: false
    t.bigint "menu_id", null: false
    t.bigint "plan_id", null: false
    t.integer "start_week", null: false
    t.datetime "updated_at", null: false
    t.index ["exercise_routine_id"], name: "index_plan_assignments_on_exercise_routine_id"
    t.index ["menu_id"], name: "index_plan_assignments_on_menu_id"
    t.index ["plan_id", "start_week", "end_week"], name: "index_plan_assignments_on_plan_and_range"
    t.index ["plan_id"], name: "index_plan_assignments_on_plan_id"
    t.check_constraint "end_week >= start_week", name: "phase_program_assignments_end_gte_start"
    t.check_constraint "start_week >= 1", name: "phase_program_assignments_start_week_gte_one"
  end

  create_table "plans", force: :cascade do |t|
    t.integer "adoption_catalog_origin_id"
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.string "name_normalized", null: false
    t.integer "public_catalog_adoptions_count", default: 0, null: false
    t.integer "public_catalog_distinct_adopters_count", default: 0, null: false
    t.boolean "publicly_shareable", default: false, null: false
    t.integer "source_plan_id"
    t.string "source_sync_fingerprint"
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["source_plan_id"], name: "index_plans_on_source_plan_id"
    t.index ["user_id", "name_normalized"], name: "index_plans_on_user_and_name_normalized", unique: true
    t.index ["user_id", "source_plan_id"], name: "index_plans_adoption_unique_per_user_and_source", unique: true, where: "(source_plan_id IS NOT NULL)"
    t.index ["user_id"], name: "index_plans_on_user_id"
  end

  create_table "sessions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "ip_address"
    t.datetime "updated_at", null: false
    t.string "user_agent"
    t.bigint "user_id", null: false
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "user_habits", force: :cascade do |t|
    t.date "activation_date"
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.integer "current_streak_today", default: 0, null: false
    t.integer "daily_target", default: 1, null: false
    t.json "frequency_params", default: {}, null: false
    t.string "frequency_type", default: "daily", null: false
    t.bigint "global_habit_template_id"
    t.bigint "habit_category_id", null: false
    t.string "habit_metric_kind", default: "none", null: false
    t.integer "longest_streak_through_today", default: 0, null: false
    t.string "name", null: false
    t.string "name_normalized", null: false
    t.boolean "reminder_email", default: false, null: false
    t.boolean "reminder_enabled", default: false, null: false
    t.string "reminder_time_of_day"
    t.boolean "reminder_web_push", default: false, null: false
    t.date "streak_counters_as_of"
    t.boolean "streak_counters_stale", default: true, null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["activation_date"], name: "index_user_habits_on_activation_date"
    t.index ["frequency_type"], name: "index_user_habits_on_frequency_type"
    t.index ["global_habit_template_id"], name: "index_user_habits_on_global_habit_template_id"
    t.index ["habit_category_id"], name: "index_user_habits_on_habit_category_id"
    t.index ["reminder_enabled", "reminder_time_of_day"], name: "idx_user_habits_reminder_slot"
    t.index ["streak_counters_stale", "streak_counters_as_of"], name: "index_user_habits_on_streak_counters_freshness"
    t.index ["user_id", "name_normalized"], name: "idx_user_habits_unique_active_name_per_user", unique: true, where: "(active = true)"
    t.index ["user_id"], name: "index_user_habits_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.boolean "allow_menu_freeform", default: true, null: false
    t.string "body_unit_system", default: "metric", null: false
    t.datetime "created_at", null: false
    t.decimal "current_bmi", precision: 4, scale: 2
    t.decimal "current_weight_kg", precision: 5, scale: 2
    t.date "date_of_birth", null: false
    t.string "email", null: false
    t.integer "height_cm", null: false
    t.string "password_digest", null: false
    t.date "phase_one_starts_on"
    t.date "phase_reminder_dismissed_on"
    t.boolean "phase_reminder_email", default: true, null: false
    t.boolean "phase_reminder_in_app", default: true, null: false
    t.string "timezone", default: "", null: false
    t.datetime "updated_at", null: false
    t.boolean "verified", default: false, null: false
    t.index ["email"], name: "index_users_on_email", unique: true
  end

  create_table "web_push_subscriptions", force: :cascade do |t|
    t.string "auth", null: false
    t.datetime "created_at", null: false
    t.string "endpoint", null: false
    t.string "p256dh", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["user_id", "endpoint"], name: "index_web_push_subscriptions_uniqueness", unique: true
    t.index ["user_id"], name: "index_web_push_subscriptions_on_user_id"
  end

  create_table "weight_logs", force: :cascade do |t|
    t.decimal "bmi", precision: 4, scale: 2, null: false
    t.datetime "created_at", null: false
    t.integer "height_cm", null: false
    t.datetime "logged_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.decimal "weight_kg", precision: 5, scale: 2, null: false
    t.index ["user_id", "logged_at"], name: "index_weight_logs_on_user_id_and_logged_at"
    t.index ["user_id"], name: "index_weight_logs_on_user_id"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "dishes", "users"
  add_foreign_key "exercise_routine_assignments", "exercise_routines"
  add_foreign_key "exercise_routine_assignments", "users"
  add_foreign_key "exercise_routine_lines", "exercise_routines"
  add_foreign_key "exercise_routines", "exercise_routines", column: "source_exercise_routine_id"
  add_foreign_key "exercise_routines", "users"
  add_foreign_key "habit_categories", "users"
  add_foreign_key "habit_completions", "user_habits"
  add_foreign_key "habit_reminder_events", "user_habits"
  add_foreign_key "habit_reminder_events", "users"
  add_foreign_key "menu_entries", "dishes"
  add_foreign_key "menu_entries", "menus"
  add_foreign_key "menus", "menus", column: "source_menu_id"
  add_foreign_key "menus", "users"
  add_foreign_key "phase_assignments", "menus"
  add_foreign_key "phase_assignments", "users"
  add_foreign_key "phase_menu_blocks", "menus"
  add_foreign_key "phase_menu_blocks", "phases"
  add_foreign_key "phase_reminder_events", "users"
  add_foreign_key "phase_routine_blocks", "exercise_routines"
  add_foreign_key "phase_routine_blocks", "phases"
  add_foreign_key "phases", "phases", column: "source_phase_id"
  add_foreign_key "phases", "users"
  add_foreign_key "plan_assignments", "exercise_routines"
  add_foreign_key "plan_assignments", "menus"
  add_foreign_key "plan_assignments", "plans"
  add_foreign_key "plans", "plans", column: "source_plan_id"
  add_foreign_key "plans", "users"
  add_foreign_key "sessions", "users"
  add_foreign_key "user_habits", "global_habit_templates"
  add_foreign_key "user_habits", "habit_categories"
  add_foreign_key "user_habits", "users"
  add_foreign_key "web_push_subscriptions", "users"
  add_foreign_key "weight_logs", "users"
end
