# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Exercise routine assignments", type: :request do
  let(:user) { create(:user, password: "Password123!", timezone: "Etc/UTC") }

  def routine!(name: "R")
    r = ExerciseRoutine.new(user: user, name: name)
    r.exercise_routine_lines.build(weekday: 0, position: 0, label: "x")
    r.tap(&:save!)
  end

  let(:routine) { routine! }

  before do
    post sign_in_path, params: { email: user.email, password: "Password123!" }
  end

  # [REQ-EXR-002]
  it "creates a routine assignment" do
    post exercise_routine_assignments_path,
      params: { exercise_routine_assignment: { exercise_routine_id: routine.id, start_week: 1, end_week: 4 } }

    expect(response).to have_http_status(:found)
    expect(ExerciseRoutineAssignment.find_by!(user: user, exercise_routine: routine).start_week).to eq(1)
  end

  # [REQ-EXR-002]
  it "rejects overlapping routine assignments" do
    ExerciseRoutineAssignment.create!(user: user, exercise_routine: routine, start_week: 1, end_week: 4)
    other = routine!(name: "Otra")

    post exercise_routine_assignments_path,
      params: { exercise_routine_assignment: { exercise_routine_id: other.id, start_week: 3, end_week: 6 } }

    expect(response).to have_http_status(:unprocessable_content)
    expect(ExerciseRoutineAssignment.where(exercise_routine: other).count).to eq(0)
  end

  # [REQ-EXR-002]
  it "forbids editing another user's assignment" do
    other = create(:user, password: "Password123!")
    foreign_routine = ExerciseRoutine.new(user: other, name: "X")
    foreign_routine.exercise_routine_lines.build(weekday: 0, position: 0, label: "x")
    foreign_routine.save!
    foreign = ExerciseRoutineAssignment.create!(
      user: other,
      exercise_routine: foreign_routine,
      start_week: 1,
      end_week: 2
    )

    get edit_exercise_routine_assignment_path(foreign)

    expect(response).to have_http_status(:not_found)
  end
end
