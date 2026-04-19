require "rails_helper"

RSpec.describe "User habits create_from_template", type: :request do
  let(:user) { create(:user, password: "Password123!") }

  before do
    post sign_in_path, params: { email: user.email, password: "Password123!" }
  end

  # [REQ-HAB-008, REQ-I18N-001]
  it "redirects with a flash when the template does not exist" do
    category = create(:habit_category, user: user)

    post create_from_template_user_habits_path,
      params: { template_id: 999_999, habit_category_id: category.id }

    expect(response).to redirect_to(user_habits_path)
    expect(flash[:alert]).to eq(I18n.t("user_habits.flash.not_found"))
  end

  # [REQ-HAB-008, REQ-I18N-001]
  it "redirects when the category does not belong to the current user" do
    template = create(:global_habit_template)
    other_user = create(:user, password: "Password123!")
    foreign_category = create(:habit_category, user: other_user)

    post create_from_template_user_habits_path,
      params: { template_id: template.id, habit_category_id: foreign_category.id }

    expect(response).to redirect_to(user_habits_path)
    expect(flash[:alert]).to eq(I18n.t("user_habits.flash.not_found"))
  end

  # [REQ-HAB-008] [REQ-DAY-005]
  it "copies suggested metrics from the template onto the new habit" do
    category = create(:habit_category, user: user)
    template = create(:global_habit_template,
      code: "custom_metric_tpl",
      suggested_habit_metric_kind: "count",
      suggested_daily_target: 7)

    post create_from_template_user_habits_path,
      params: { template_id: template.id, habit_category_id: category.id }

    expect(response).to redirect_to(user_habits_path)
    habit = UserHabit.find_by!(user: user, global_habit_template: template)
    expect(habit.habit_metric_kind).to eq("count")
    expect(habit.daily_target).to eq(7)
  end
end
