# frozen_string_literal: true

require "rails_helper"

RSpec.describe PlanAssignment, type: :model do
  let(:user) { create(:user, password: "Password123!") }
  let(:plan) { Plan.create!(user: user, name: "Plan A") }
  let(:menu_a) { Menu.create!(user: user, name: "Menú A") }
  let(:menu_b) { Menu.create!(user: user, name: "Menú B") }

  def routine_for(user, name)
    r = ExerciseRoutine.new(user: user, name: name)
    r.exercise_routine_lines.build(weekday: 0, position: 0, label: "Línea")
    r.save!
    r
  end

  let(:routine_a) { routine_for(user, "Rutina A") }
  let(:routine_b) { routine_for(user, "Rutina B") }

  # [REQ-PHS-001]
  it "rejects end_week before start_week" do
    row = described_class.new(
      plan: plan,
      menu: menu_a,
      exercise_routine: routine_a,
      start_week: 5,
      end_week: 3
    )
    expect(row).not_to be_valid
    expect(row.errors.added?(:end_week, :before_start_week)).to eq(true)
  end

  # [REQ-PHS-001]
  it "rejects overlapping week ranges within the same plan" do
    described_class.create!(
      plan: plan,
      menu: menu_a,
      exercise_routine: routine_a,
      start_week: 1,
      end_week: 4
    )
    dup = described_class.new(
      plan: plan,
      menu: menu_b,
      exercise_routine: routine_b,
      start_week: 3,
      end_week: 6
    )
    expect(dup).not_to be_valid
    expect(dup.errors.added?(:base, :range_overlap)).to eq(true)
  end

  # [REQ-PHS-001]
  it "allows adjacent ranges on the same plan (no overlap)" do
    described_class.create!(
      plan: plan,
      menu: menu_a,
      exercise_routine: routine_a,
      start_week: 1,
      end_week: 4
    )
    ok = described_class.create!(
      plan: plan,
      menu: menu_b,
      exercise_routine: routine_b,
      start_week: 5,
      end_week: 8
    )
    expect(ok).to be_persisted
  end

  # [REQ-PHS-001]
  it "rejects a menu that belongs to another user" do
    other = create(:user, password: "Password123!")
    foreign_menu = Menu.create!(user: other, name: "Ajeno")
    row = described_class.new(
      plan: plan,
      menu: foreign_menu,
      exercise_routine: routine_a,
      start_week: 1,
      end_week: 2
    )
    expect(row).not_to be_valid
    expect(row.errors.added?(:menu_id, :must_match_user)).to eq(true)
  end

  # [REQ-PHS-001]
  it "rejects an exercise routine that belongs to another user" do
    other = create(:user, password: "Password123!")
    foreign_routine = routine_for(other, "Ajena")
    row = described_class.new(
      plan: plan,
      menu: menu_a,
      exercise_routine: foreign_routine,
      start_week: 1,
      end_week: 2
    )
    expect(row).not_to be_valid
    expect(row.errors.added?(:exercise_routine_id, :must_match_user)).to eq(true)
  end

  # [REQ-PHS-001]
  it "does not treat ranges on different plans as overlapping" do
    other_plan = Plan.create!(user: user, name: "Plan B")
    described_class.create!(
      plan: plan,
      menu: menu_a,
      exercise_routine: routine_a,
      start_week: 1,
      end_week: 4
    )
    ok = described_class.create!(
      plan: other_plan,
      menu: menu_b,
      exercise_routine: routine_b,
      start_week: 2,
      end_week: 5
    )
    expect(ok).to be_persisted
  end
end
