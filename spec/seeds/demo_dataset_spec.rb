# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Demo dataset seeds" do
  include ActiveJob::TestHelper

  let(:demo_emails) do
    [
      "demo+mx-metric@moonloop.local",
      "demo+es-imperial@moonloop.local",
      "demo+us-metric@moonloop.local"
    ]
  end

  # [REQ-PLAT-001]
  it "is idempotent for demo users" do
    Rails.application.load_seed
    first_count = User.where(email: demo_emails).count

    Rails.application.load_seed
    second_count = User.where(email: demo_emails).count

    expect(first_count).to eq(3)
    expect(second_count).to eq(3)
  end

  # [REQ-PLAT-001]
  it "sets stable demo profile attributes" do
    Rails.application.load_seed

    mx = User.find_by!(email: "demo+mx-metric@moonloop.local")
    es = User.find_by!(email: "demo+es-imperial@moonloop.local")
    us = User.find_by!(email: "demo+us-metric@moonloop.local")

    expect(mx.timezone).to eq("America/Mexico_City")
    expect(mx.body_unit_system).to eq("metric")

    expect(es.timezone).to eq("Europe/Madrid")
    expect(es.body_unit_system).to eq("imperial_us")

    expect(us.timezone).to eq("America/Los_Angeles")
    expect(us.body_unit_system).to eq("metric")
  end

  # [REQ-HAB-002, REQ-DAY-005]
  it "provisions default habits (including metric/target defaults) for demo users" do
    Rails.application.load_seed

    demo_emails.each do |email|
      user = User.find_by!(email: email)

      expect(user.user_habits.count).to be > 0

      water_template = GlobalHabitTemplate.find_by!(code: "fitness_water")
      water_habit = UserHabit.find_by!(user: user, global_habit_template: water_template)
      expect(water_habit.habit_metric_kind).to eq("count")
      expect(water_habit.daily_target).to eq(8)

      exercise_template = GlobalHabitTemplate.find_by!(code: "fitness_exercise")
      exercise_habit = UserHabit.find_by!(user: user, global_habit_template: exercise_template)
      expect(exercise_habit.habit_metric_kind).to eq("duration_min")
      expect(exercise_habit.daily_target).to eq(30)
    end
  end

  # [REQ-DAY-002, REQ-DAY-005]
  it "creates at least one completion for today (user-local) on a measurable habit" do
    Rails.application.load_seed

    demo_emails.each do |email|
      user = User.find_by!(email: email)
      user_today = Time.find_zone!(user.timezone).today
      user_yesterday = user_today - 1

      water_template = GlobalHabitTemplate.find_by!(code: "fitness_water")
      water_habit = UserHabit.find_by!(user: user, global_habit_template: water_template)

      today_completion = HabitCompletion.find_by(user_habit: water_habit, completed_on: user_today)
      expect(today_completion).to be_present

      yesterday_completion = HabitCompletion.find_by(user_habit: water_habit, completed_on: user_yesterday)
      expect(yesterday_completion).to be_present
    end
  end

  # [REQ-WGT-001, REQ-WGT-002]
  it "creates a small weight log history and reconciles current stats" do
    Rails.application.load_seed

    demo_emails.each do |email|
      user = User.find_by!(email: email)

      expect(user.weight_logs.count).to be_between(8, 12)

      latest = user.weight_logs.order(logged_at: :desc, id: :desc).first
      expect(latest).to be_present

      user.reload
      expect(user.current_weight_kg).to eq(latest.weight_kg)
      expect(user.current_bmi).to eq(latest.bmi)
    end
  end

  # [REQ-MENU-001, REQ-MENU-003]
  it "seeds a menu and a phase assignment covering the current week" do
    Rails.application.load_seed

    demo_emails.each do |email|
      user = User.find_by!(email: email)

      expect(user.phase_one_starts_on).to be_present
      user_today = Time.find_zone!(user.timezone).today
      week = Phases::WeekNumber.for_local_date(user: user, local_date: user_today)
      expect(week).to be_present

      expect(user.menus.count).to be >= 1

      active_assignment = user.phase_assignments.where("start_week <= ? AND end_week >= ?", week, week).first
      expect(active_assignment).to be_present

      expect(active_assignment.menu.menu_entries.count).to be > 0
    end
  end

  # [REQ-EXR-001, REQ-EXR-002]
  it "seeds an exercise routine and assignment covering the current week" do
    Rails.application.load_seed

    demo_emails.each do |email|
      user = User.find_by!(email: email)

      user_today = Time.find_zone!(user.timezone).today
      week = Phases::WeekNumber.for_local_date(user: user, local_date: user_today)
      expect(week).to be_present

      expect(user.exercise_routines.count).to be >= 1

      assignment =
        user.exercise_routine_assignments.where("start_week <= ? AND end_week >= ?", week, week).first
      expect(assignment).to be_present

      routine = assignment.exercise_routine
      expect(routine.exercise_routine_lines.count).to be > 0
    end
  end

  # [REQ-PHS-001]
  it "seeds a phase program (bundle) and can apply it to a demo user" do
    Rails.application.load_seed

    user = User.find_by!(email: "demo+mx-metric@moonloop.local")
    expect(user.phase_programs.count).to be >= 1

    program = user.phase_programs.first
    expect(program.phase_program_assignments.count).to be > 0

    Programs::ApplyBundleToUser.call(phase_program: program, user: user)

    expect(user.phase_assignments.count).to eq(program.phase_program_assignments.count)
    expect(user.exercise_routine_assignments.count).to eq(program.phase_program_assignments.count)
  end

  # [REQ-PLAT-001]
  it "does not enqueue background jobs as a side effect" do
    ActiveJob::Base.queue_adapter = :test
    clear_enqueued_jobs

    Rails.application.load_seed

    expect(enqueued_jobs).to be_empty
  end

  # [REQ-MENU-001, REQ-MENU-002]
  it "seeds at least one recipe and links a menu entry to it" do
    Rails.application.load_seed

    demo_emails.each do |email|
      user = User.find_by!(email: email)

      expect(user.recipes.count).to be >= 1

      entry = MenuEntry.joins(:menu).where(menus: { user_id: user.id }).where.not(recipe_id: nil).first
      expect(entry).to be_present
      expect(entry.recipe.user_id).to eq(user.id)
    end
  end
end

