require "rails_helper"

RSpec.describe "User habits", type: :system do
  include ActionView::RecordIdentifier

  let(:user) { create(:user, password: "Password123!") }

  before do
    driven_by(:rack_test)

    visit sign_in_path
    fill_in "Correo electrónico", with: user.email
    fill_in "Contraseña", with: "Password123!"
    click_button "Iniciar sesión"
  end

  # [REQ-HAB-008, REQ-I18N-001]
  it "groups habits under their category headings" do
    nutrition = HabitCategory.create!(user: user, name: "Nutrition", name_normalized: "nutrition")
    fitness = HabitCategory.create!(user: user, name: "Fitness", name_normalized: "fitness")

    UserHabit.create!(user: user, habit_category: nutrition, name: "Breakfast", name_normalized: "breakfast", active: true)
    UserHabit.create!(user: user, habit_category: fitness, name: "Water", name_normalized: "water", active: true)

    visit user_habits_path

    expect(page).to have_css("h2", text: "Nutrition")
    expect(page).to have_css("h2", text: "Fitness")
    expect(page).to have_content("Breakfast")
    expect(page).to have_content("Water")
  end

  # [REQ-HAB-007, REQ-I18N-001]
  it "allows toggling active state" do
    category = HabitCategory.create!(user: user, name: "Fitness", name_normalized: "fitness")
    habit = UserHabit.create!(user: user, habit_category: category, name: "Water", name_normalized: "water", active: true)

    visit user_habits_path

    within("##{dom_id(habit)}") do
      click_button "Desactivar"
    end

    expect(habit.reload.active).to eq(false)

    within("##{dom_id(habit)}") do
      click_button "Activar"
    end

    expect(habit.reload.active).to eq(true)
  end

  # [REQ-HAB-008, REQ-I18N-001]
  it "allows creating a personal habit" do
    category = HabitCategory.create!(user: user, name: "Fitness", name_normalized: "fitness")

    visit user_habits_path

    select category.name, from: "Categoría"
    fill_in "Nombre", with: "Stretch"
    click_button "Crear hábito personal"

    expect(page).to have_content("Stretch")
    expect(UserHabit.find_by!(user: user, name_normalized: "stretch").global_habit_template_id).to be_nil
  end

  # [REQ-HAB-008, REQ-I18N-001]
  it "allows adding a habit from a global template" do
    category = HabitCategory.create!(user: user, name: "Nutrition", name_normalized: "nutrition")
    template = GlobalHabitTemplate.create!(code: "nutrition_breakfast")

    visit user_habits_path

    within("##{dom_id(template)}") do
      select category.name, from: "Categoría"
      click_button "Agregar desde plantilla"
    end

    habit = UserHabit.find_by!(user: user, global_habit_template_id: template.id)
    expect(habit).to be_present
    expect(page).to have_content("Desayuno")
  end

  # [REQ-HAB-006, REQ-I18N-001]
  it "shows validation errors for duplicate active names (case-insensitive + trim)" do
    category = HabitCategory.create!(user: user, name: "Fitness", name_normalized: "fitness")
    UserHabit.create!(user: user, habit_category: category, name: "Water", name_normalized: "water", active: true)

    visit user_habits_path

    select category.name, from: "Categoría"
    fill_in "Nombre", with: " water "
    click_button "Crear hábito personal"

    expect(page).to have_content("ya está en uso")
  end

  # [REQ-HAB-008]
  it "does not expose a delete route for habits" do
    expect {
      Rails.application.routes.recognize_path("/user_habits/1", method: :delete)
    }.to raise_error(ActionController::RoutingError)
  end
end
