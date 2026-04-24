# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

DEMO_USERS = [
  {
    email: "demo+mx-metric@moonloop.local",
    timezone: "America/Mexico_City",
    body_unit_system: "metric"
  },
  {
    email: "demo+es-imperial@moonloop.local",
    timezone: "Europe/Madrid",
    body_unit_system: "imperial_us"
  },
  {
    email: "demo+us-metric@moonloop.local",
    timezone: "America/Los_Angeles",
    body_unit_system: "metric"
  }
].freeze unless defined?(DEMO_USERS)

def seed_demo_users!
  raise "DEMO_USERS must be present" if DEMO_USERS.empty?

  DEMO_USERS.each do |attrs|
    raise "demo email required" if attrs[:email].blank?
    raise "demo timezone required" if attrs[:timezone].blank?

    user = User.find_or_initialize_by(email: attrs[:email])

    user.assign_attributes(
      timezone: attrs[:timezone],
      body_unit_system: attrs[:body_unit_system]
    )
    if user.new_record?
      user.assign_attributes(
        date_of_birth: Date.new(1990, 1, 1),
        height_cm: 175
      )
    end
    user.password = "moonloop-demo-password"
    user.password_confirmation = "moonloop-demo-password"

    user.save!

    ProvisionDefaultHabitsJob.perform_now(user_id: user.id)

    seed_local_recent_completions!(user)
    seed_weight_history!(user)
    seed_menu_and_phase!(user)
    seed_exercise_routine_and_assignment!(user)
  end

  demo_count = User.where(email: DEMO_USERS.map { |u| u[:email] }).count
  raise "expected 3 demo users, got #{demo_count}" unless demo_count == 3
end

def seed_local_recent_completions!(user)
  raise ArgumentError, "user must be persisted" unless user.persisted?

  user_today = Time.find_zone!(user.timezone).today
  user_yesterday = user_today - 1

  water_template = GlobalHabitTemplate.find_by!(code: "fitness_water")
  water_habit = UserHabit.find_by!(user: user, global_habit_template: water_template)
  raise "expected fitness_water habit for #{user.email}" unless water_habit

  # For "daily" habits without activation_date, due-day start defaults to created_at (local date).
  # Seeds need "yesterday" to be a due day, so we anchor activation_date before recording completions.
  if water_habit.habit_completions.none? && (water_habit.activation_date.blank? || water_habit.activation_date > user_yesterday)
    water_habit.update!(activation_date: user_yesterday)
  end

  [user_yesterday, user_today].each do |local_date|
    Habits::RecordCompletion.call(
      user: user,
      user_habit: water_habit,
      local_date: local_date,
      status: "done",
      day_progress: water_habit.daily_target
    )

    completion = HabitCompletion.find_by(user_habit: water_habit, completed_on: local_date)
    raise "expected a water completion for #{user.email} on #{local_date}" unless completion
  end
end

def seed_weight_history!(user)
  raise ArgumentError, "user must be persisted" unless user.persisted?

  existing = user.weight_logs.count
  return if existing.positive?

  zone = Time.find_zone!(user.timezone)
  user_today = zone.today
  user_now = zone.now

  # Deterministic per user (stable across runs)
  rng_seed = user.email.to_s.bytes.sum
  rng = Random.new(rng_seed)

  log_count = 10
  raise "log_count must be within 8..12" unless log_count.between?(8, 12)

  base_weight_kg = 72.0 + (rng.rand * 6.0) # 72–78kg
  step_kg = 0.15 + (rng.rand * 0.15) # 0.15–0.30kg per step

  # 10 logs weekly over ~9 weeks, ending today.
  (log_count - 1).downto(0) do |weeks_ago|
    local_date = user_today - (weeks_ago * 7)
    candidate = zone.local(local_date.year, local_date.month, local_date.day, 9, 0, 0)
    logged_at =
      if weeks_ago.zero? && candidate > user_now
        # WeightLog validates logged_at is not in the future (in the user's timezone).
        user_now - 1.hour
      else
        candidate
      end

    idx = (log_count - 1) - weeks_ago
    weight_kg = (base_weight_kg + (idx * step_kg)).round(2)

    LogWeightService.new(user: user, weight_kg: weight_kg, logged_at: logged_at).call
  end

  count_after = user.weight_logs.count
  raise "expected 8..12 weight logs, got #{count_after}" unless count_after.between?(8, 12)
end

def seed_menu_and_phase!(user)
  raise ArgumentError, "user must be persisted" unless user.persisted?

  zone = Time.find_zone!(user.timezone)
  user_today = zone.today

  if user.phase_one_starts_on.blank? || user.phase_one_starts_on > user_today
    user.update!(phase_one_starts_on: user_today - 21)
  end

  menu_name = "Demo semanal"
  menu =
    Menu.find_or_create_by!(user: user, name_normalized: menu_name.strip.downcase) do |m|
      m.name = menu_name
    end

  # Keep menu small but non-empty for /phase and related surfaces.
  [
    { weekday: 1, meal_type: "desayuno", text: "Avena con fruta" },
    { weekday: 1, meal_type: "almuerzo", text: "Ensalada + proteína" },
    { weekday: 1, meal_type: "cena", text: "Sopa + pan" },
    { weekday: 3, meal_type: "desayuno", text: "Huevos + café" }
  ].each do |entry|
    Menus::UpsertEntry.call(
      user: user,
      menu: menu,
      weekday: entry[:weekday],
      meal_type: entry[:meal_type],
      recipe_id: nil,
      freeform_text: entry[:text]
    )
  end

  week = Phases::WeekNumber.for_local_date(user: user, local_date: user_today)
  raise "expected a phase week number for #{user.email}" unless week

  covers_week = user.phase_assignments.where("start_week <= ? AND end_week >= ?", week, week).exists?
  unless covers_week
    PhaseAssignment.transaction do
      user.phase_assignments.delete_all
      user.phase_assignments.create!(menu: menu, start_week: 1, end_week: 200)
    end
  end

  unless menu.menu_entries.exists?
    raise "expected seeded menu entries for #{user.email}"
  end
end

def seed_exercise_routine_and_assignment!(user)
  raise ArgumentError, "user must be persisted" unless user.persisted?

  zone = Time.find_zone!(user.timezone)
  user_today = zone.today

  # Week number requires a phase anchor; menu seeding ensures it, but keep this resilient.
  if user.phase_one_starts_on.blank? || user.phase_one_starts_on > user_today
    user.update!(phase_one_starts_on: user_today - 21)
  end

  routine_name = "Demo rutina"
  routine =
    ExerciseRoutine.find_or_create_by!(user: user, name_normalized: routine_name.strip.downcase) do |r|
      r.name = routine_name
      r.exercise_routine_lines.build(weekday: 1, position: 0, label: "Caminata 30 min", notes: nil)
    end

  if routine.exercise_routine_lines.none?
    routine.exercise_routine_lines.create!(weekday: 1, position: 0, label: "Caminata 30 min", notes: nil)
  end

  week = Phases::WeekNumber.for_local_date(user: user, local_date: user_today)
  raise "expected a phase week number for #{user.email}" unless week

  covers_week = user.exercise_routine_assignments.where("start_week <= ? AND end_week >= ?", week, week).exists?
  unless covers_week
    ExerciseRoutineAssignment.transaction do
      user.exercise_routine_assignments.delete_all
      user.exercise_routine_assignments.create!(exercise_routine: routine, start_week: 1, end_week: 200)
    end
  end
end

seed_demo_users!
