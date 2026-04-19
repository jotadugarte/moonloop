require "rails_helper"

RSpec.describe ProvisionDefaultHabitsJob, type: :job do
  include ActiveJob::TestHelper

  let(:user) { create(:user) }

  around do |example|
    clear_enqueued_jobs
    clear_performed_jobs
    perform_enqueued_jobs { example.run }
  end

  def stub_default_catalog!
    # We keep codes locale-neutral (English); display names come from i18n.
    allow(ProvisionDefaultHabitsJob).to receive(:default_template_codes).and_return(
      %w[
        nutrition_breakfast
        nutrition_lunch
        nutrition_dinner
        nutrition_snack
        fitness_exercise
        fitness_water
        emotional_pet
      ]
    )
  end

  # [REQ-HAB-002]
  it "is idempotent by template code (can run multiple times without duplicates)" do
    stub_default_catalog!

    expect {
      described_class.perform_now(user_id: user.id)
      described_class.perform_now(user_id: user.id)
    }.to change(GlobalHabitTemplate, :count).by(7)
      .and change(UserHabit, :count).by(7)
      .and change(HabitCategory, :count).by(3)
  end

  # [REQ-HAB-002] [REQ-DAY-005]
  it "copies suggested metric defaults from templates onto provisioned habits" do
    stub_default_catalog!

    described_class.perform_now(user_id: user.id)

    water_template = GlobalHabitTemplate.find_by!(code: "fitness_water")
    exercise_template = GlobalHabitTemplate.find_by!(code: "fitness_exercise")
    expect(water_template.suggested_habit_metric_kind).to eq("count")
    expect(water_template.suggested_daily_target).to eq(8)

    water_habit = UserHabit.find_by!(user: user, global_habit_template: water_template)
    expect(water_habit.habit_metric_kind).to eq("count")
    expect(water_habit.daily_target).to eq(8)

    exercise_habit = UserHabit.find_by!(user: user, global_habit_template: exercise_template)
    expect(exercise_habit.habit_metric_kind).to eq("duration_min")
    expect(exercise_habit.daily_target).to eq(30)
  end

  # [REQ-HAB-002]
  it "retries on transient failures without creating duplicates" do
    stub_default_catalog!

    call_count = 0
    allow(GlobalHabitTemplate).to receive(:find_or_create_by!).and_wrap_original do |m, *args, **kwargs|
      call_count += 1
      raise ActiveRecord::Deadlocked if call_count == 1
      m.call(*args, **kwargs)
    end

    expect {
      described_class.perform_now(user_id: user.id)
    }.not_to raise_error

    expect(GlobalHabitTemplate.count).to eq(7)
    expect(UserHabit.count).to eq(7)
  end
end
