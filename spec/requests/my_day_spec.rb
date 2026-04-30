# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Mi Día (My Day)", type: :request do
  let(:user) { create(:user, password: "Password123!", timezone: "Etc/UTC") }

  before do
    post sign_in_path, params: { email: user.email, password: "Password123!" }
  end

  # [REQ-DAY-001]
  it "renders the page for the signed-in user" do
    get my_day_path

    expect(response).to have_http_status(:ok)
    expect(response.body).to include(I18n.t("my_day.show.heading"))
  end

  # [REQ-DAY-001] [REQ-DAY-005]
  it "shows metric progress and actions for measurable habits" do
    travel_to Time.utc(2026, 4, 16, 12, 0, 0) do
      category = create(:habit_category, user: user, name: "Salud")
      habit = create(:user_habit,
        user: user,
        habit_category: category,
        name: "Vasitos",
        frequency_type: "daily",
        activation_date: Date.new(2026, 1, 1),
        habit_metric_kind: "count",
        daily_target: 5)
      create(:habit_completion,
        user_habit: habit,
        completed_on: Date.new(2026, 4, 16),
        status: "failed",
        day_progress: 2)

      get my_day_path

      expect(response.body).to include('data-test="my-day-metric-progress"')
      expect(response.body).to include(
        I18n.t("my_day.show.metric_progress_count", current: 2, target: 5)
      )
      expect(response.body).to include(I18n.t("my_day.actions.add_one"))
      expect(response.body).to include(I18n.t("my_day.actions.meet_target"))
    end
  end

  # [REQ-DAY-001]
  it "lists active habits that are due on the user's local today" do
    travel_to Time.utc(2026, 4, 16, 12, 0, 0) do
      category = create(:habit_category, user: user, name: "Salud")
      create(:user_habit,
        user: user,
        habit_category: category,
        name: "Agua diaria",
        frequency_type: "daily",
        activation_date: Date.new(2026, 1, 1))

      get my_day_path

      expect(response.body).to include("Agua diaria")
      expect(response.body).to include("Salud")
    end
  end

  # [REQ-DAY-001]
  it "does not list inactive habits" do
    travel_to Time.utc(2026, 4, 16, 12, 0, 0) do
      category = create(:habit_category, user: user)
      create(:user_habit,
        user: user,
        habit_category: category,
        name: "Inactivo",
        frequency_type: "daily",
        activation_date: Date.new(2026, 1, 1),
        active: false)

      get my_day_path

      expect(response.body).not_to include("Inactivo")
    end
  end

  # [REQ-DAY-001]
  it "does not list habits that are not due on that local day" do
    travel_to Time.utc(2026, 4, 16, 12, 0, 0) do
      # 2026-04-16 is Thursday (wday 4); only Mon/Tue in schedule
      category = create(:habit_category, user: user)
      create(:user_habit,
        user: user,
        habit_category: category,
        name: "Solo Lun Mar",
        frequency_type: "weekdays",
        frequency_params: { "weekdays" => [ 1, 2 ] },
        activation_date: Date.new(2026, 1, 1))

      get my_day_path

      expect(response.body).not_to include("Solo Lun Mar")
    end
  end

  # [REQ-DAY-003]
  it "lists habits for a selected past local date" do
    travel_to Time.utc(2026, 4, 16, 12, 0, 0) do
      category = create(:habit_category, user: user, name: "Salud")
      create(:user_habit,
        user: user,
        habit_category: category,
        name: "Agua diaria",
        frequency_type: "daily",
        activation_date: Date.new(2026, 1, 1))

      get my_day_path, params: { fecha: "2026-04-10" }

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Agua diaria")
    end
  end

  # [REQ-DAY-003]
  it "rejects a future selected date" do
    travel_to Time.utc(2026, 4, 16, 12, 0, 0) do
      get my_day_path, params: { fecha: "2026-04-20" }

      expect(response).to redirect_to(my_day_path)
      expect(flash[:alert]).to eq(I18n.t("my_day.flash.future_date_not_allowed"))
    end
  end

  # [REQ-DAY-003]
  it "rejects an invalid date parameter" do
    travel_to Time.utc(2026, 4, 16, 12, 0, 0) do
      get my_day_path, params: { fecha: "not-a-date" }

      expect(response).to redirect_to(my_day_path)
      expect(flash[:alert]).to eq(I18n.t("my_day.flash.invalid_date"))
    end
  end

  # [REQ-DAY-001]
  it "does not list habits before their activation_date window" do
    travel_to Time.utc(2026, 4, 16, 12, 0, 0) do
      category = create(:habit_category, user: user)
      create(:user_habit,
        user: user,
        habit_category: category,
        name: "Empieza después",
        frequency_type: "every_x_days",
        frequency_params: { "interval" => 1 },
        activation_date: Date.new(2026, 5, 1))

      get my_day_path

      expect(response.body).not_to include("Empieza después")
    end
  end

  # [REQ-EXR-003]
  it "always exposes global exercise shortcut" do
    get my_day_path

    expect(response.body).to include('data-test="my-day-exercise-shortcut"')
    expect(response.body).to include(exercise_routines_path)
  end

  # [REQ-EXR-003]
  it "shows active routine preview for fitness_exercise when that habit is due" do
    travel_to Time.utc(2026, 4, 16, 12, 0, 0) do
      user.update!(phase_one_starts_on: Date.new(2026, 4, 10), timezone: "Etc/UTC")
      category = create(:habit_category, user: user)
      template = create(:global_habit_template, code: "fitness_exercise")
      create(:user_habit,
        user: user,
        habit_category: category,
        global_habit_template: template,
        name: "Ejercicio",
        frequency_type: "daily",
        activation_date: Date.new(2026, 1, 1))

      routine = ExerciseRoutine.new(user: user, name: "Gym A")
      routine.exercise_routine_lines.build(weekday: 4, position: 0, label: "Press banca")
      routine.save!

      ExerciseRoutineAssignment.create!(user: user, exercise_routine: routine, start_week: 1, end_week: 4)

      get my_day_path

      expect(response.body).to include('data-test="my-day-exercise-inline"')
      expect(response.body).to include("Gym A")
      expect(response.body).to include("Press banca")
      expect(response.body).to include(edit_exercise_routine_path(routine))
    end
  end

  # [REQ-EXR-003]
  it "does not show inline routine when fitness_exercise is not due that day" do
    travel_to Time.utc(2026, 4, 16, 12, 0, 0) do
      user.update!(phase_one_starts_on: Date.new(2026, 4, 10), timezone: "Etc/UTC")
      category = create(:habit_category, user: user)
      template = create(:global_habit_template, code: "fitness_exercise")
      create(:user_habit,
        user: user,
        habit_category: category,
        global_habit_template: template,
        name: "Ejercicio",
        frequency_type: "weekdays",
        frequency_params: { "weekdays" => [ 1 ] },
        activation_date: Date.new(2026, 1, 1))

      routine = ExerciseRoutine.new(user: user, name: "Gym A")
      routine.exercise_routine_lines.build(weekday: 4, position: 0, label: "Press banca")
      routine.save!

      ExerciseRoutineAssignment.create!(user: user, exercise_routine: routine, start_week: 1, end_week: 4)

      get my_day_path

      expect(response.body).not_to include('data-test="my-day-exercise-inline"')
      expect(response.body).to include('data-test="my-day-exercise-shortcut"')
    end
  end

  # [REQ-EXR-003]
  it "shows a disabled block when fitness_exercise exists but is inactive" do
    travel_to Time.utc(2026, 4, 16, 12, 0, 0) do
      user.update!(phase_one_starts_on: Date.new(2026, 4, 10), timezone: "Etc/UTC")
      category = create(:habit_category, user: user)
      template = create(:global_habit_template, code: "fitness_exercise")
      create(:user_habit,
        user: user,
        habit_category: category,
        global_habit_template: template,
        name: "Ejercicio",
        frequency_type: "daily",
        activation_date: Date.new(2026, 1, 1),
        active: false)

      get my_day_path

      expect(response.body).to include('data-test="my-day-exercise-inactive"')
      expect(response.body).not_to include('data-test="my-day-exercise-inline"')
      expect(response.body).to include(user_habits_path)
    end
  end

  # [REQ-EXR-003]
  it "shows inline guidance when due but no routine is assigned for the week" do
    travel_to Time.utc(2026, 4, 16, 12, 0, 0) do
      user.update!(phase_one_starts_on: Date.new(2026, 4, 10), timezone: "Etc/UTC")
      category = create(:habit_category, user: user)
      template = create(:global_habit_template, code: "fitness_exercise")
      create(:user_habit,
        user: user,
        habit_category: category,
        global_habit_template: template,
        name: "Ejercicio",
        frequency_type: "daily",
        activation_date: Date.new(2026, 1, 1))

      get my_day_path

      expect(response.body).to include('data-test="my-day-exercise-inline"')
      expect(response.body).to include(I18n.t("my_day.show.exercise_no_routine_this_week"))
    end
  end

  # [REQ-DAY-005]
  it "records +1 from Mi Día for a measurable habit" do
    travel_to Time.utc(2026, 4, 16, 12, 0, 0) do
      category = create(:habit_category, user: user)
      habit = create(:user_habit,
        user: user,
        habit_category: category,
        name: "Agua",
        frequency_type: "daily",
        activation_date: Date.new(2026, 1, 1),
        habit_metric_kind: "count",
        daily_target: 5)
      create(:habit_completion,
        user_habit: habit,
        completed_on: Date.new(2026, 4, 16),
        status: "failed",
        day_progress: 2)

      post habit_completions_path,
        params: {
          habit_completion: {
            user_habit_id: habit.id,
            completed_on: "2026-04-16",
            status: "done",
            day_progress: "3"
          }
        }

      expect(response).to redirect_to(my_day_path)
      row = HabitCompletion.find_by!(user_habit: habit, completed_on: Date.new(2026, 4, 16))
      expect(row.day_progress).to eq(3)
      expect(row.status).to eq("failed")
      expect(row.marked_failed_by_user).to be(false)
    end
  end

  # [REQ-DAY-005]
  it "shows in-progress label for measurable habits below target without explicit failure" do
    travel_to Time.utc(2026, 4, 16, 12, 0, 0) do
      category = create(:habit_category, user: user)
      habit = create(:user_habit,
        user: user,
        habit_category: category,
        name: "Agua",
        frequency_type: "daily",
        activation_date: Date.new(2026, 1, 1),
        habit_metric_kind: "count",
        daily_target: 5)
      create(:habit_completion,
        user_habit: habit,
        completed_on: Date.new(2026, 4, 16),
        status: "failed",
        day_progress: 2,
        marked_failed_by_user: false)

      get my_day_path

      expect(response.body).to include(I18n.t("habit_completions.status.in_progress"))
      expect(response.body).not_to include(I18n.t("habit_completions.status.failed"))
    end
  end
end
