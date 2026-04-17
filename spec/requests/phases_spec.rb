# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Phases dashboard", type: :request do
  let(:user) { create(:user, password: "Password123!", timezone: "Etc/UTC") }

  before do
    post sign_in_path, params: { email: user.email, password: "Password123!" }
  end

  # [REQ-MENU-003]
  it "shows the phase plan with current week when anchor is set" do
    user.update!(phase_one_starts_on: Date.new(2026, 4, 10))
    travel_to(Date.new(2026, 4, 12)) do
      get phase_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include(I18n.t("phases.show.current_week", index: 1))
    end
  end

  # [REQ-MENU-003]
  it "updates the phase 1 start date" do
    patch phase_path, params: { user: { phase_one_starts_on: "2026-05-01" } }

    expect(response).to have_http_status(:found)
    expect(user.reload.phase_one_starts_on).to eq(Date.new(2026, 5, 1))
  end

  # [REQ-MENU-004]
  it "warns when phase 1 start is more than three local days after today" do
    user.update!(timezone: "America/New_York")
    ny = ActiveSupport::TimeZone["America/New_York"].local(2026, 4, 17, 12, 0, 0)
    travel_to(ny) do
      patch phase_path, params: { user: { phase_one_starts_on: "2026-04-21" } }

      expect(response).to redirect_to(phase_path)
      expect(flash[:notice]).to eq(I18n.t("phases.flash.anchor_updated"))
      expect(flash[:alert]).to eq(I18n.t("phases.flash.anchor_far_future_warning"))
      expect(user.reload.phase_one_starts_on).to eq(Date.new(2026, 4, 21))
    end
  end

  # [REQ-MENU-004]
  it "does not warn when phase 1 start is exactly three local days after today" do
    user.update!(timezone: "America/New_York")
    ny = ActiveSupport::TimeZone["America/New_York"].local(2026, 4, 17, 12, 0, 0)
    travel_to(ny) do
      patch phase_path, params: { user: { phase_one_starts_on: "2026-04-20" } }

      expect(response).to redirect_to(phase_path)
      expect(flash[:alert]).to be_blank
    end
  end

  # [REQ-MENU-004]
  it "updates phase reminder channel preferences independently" do
    patch phase_path, params: {
      user: {
        phase_reminder_in_app: "0",
        phase_reminder_email: "1"
      }
    }

    expect(response).to redirect_to(phase_path)
    user.reload
    expect(user.phase_reminder_in_app).to eq(false)
    expect(user.phase_reminder_email).to eq(true)
  end

  # [REQ-MENU-005]
  it "repeats the last assignment block when requested" do
    menu = Menu.create!(user: user, name: "Plan")
    PhaseAssignment.create!(user: user, menu: menu, start_week: 1, end_week: 4)

    post repeat_last_assignment_phase_path

    expect(response).to redirect_to(phase_path)
    expect(flash[:notice]).to eq(I18n.t("phases.flash.repeat_last_assignment_created"))
    added = PhaseAssignment.order(:start_week).last
    expect(added.start_week).to eq(5)
    expect(added.end_week).to eq(8)
    expect(added.menu_id).to eq(menu.id)
  end

  # [REQ-MENU-005]
  it "does not repeat when there are no assignments" do
    post repeat_last_assignment_phase_path

    expect(response).to redirect_to(phase_path)
    expect(flash[:alert]).to eq(I18n.t("phases.flash.repeat_last_assignment_nothing_to_repeat"))
  end

  # [REQ-EXR-005]
  it "repeats the last routine assignment block when requested" do
    routine = ExerciseRoutine.new(user: user, name: "R")
    routine.exercise_routine_lines.build(weekday: 0, position: 0, label: "x")
    routine.save!
    ExerciseRoutineAssignment.create!(user: user, exercise_routine: routine, start_week: 1, end_week: 4)

    post repeat_last_routine_assignment_phase_path

    expect(response).to redirect_to(phase_path)
    expect(flash[:notice]).to eq(I18n.t("phases.flash.repeat_last_routine_assignment_created"))
    added = ExerciseRoutineAssignment.order(:start_week).last
    expect(added.start_week).to eq(5)
    expect(added.end_week).to eq(8)
    expect(added.exercise_routine_id).to eq(routine.id)
  end

  # [REQ-EXR-005]
  it "does not repeat routine when there are no routine assignments" do
    post repeat_last_routine_assignment_phase_path

    expect(response).to redirect_to(phase_path)
    expect(flash[:alert]).to eq(I18n.t("phases.flash.repeat_last_routine_assignment_nothing_to_repeat"))
  end
end
