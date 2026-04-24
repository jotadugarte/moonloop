# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Demo dataset seeds" do
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
end

