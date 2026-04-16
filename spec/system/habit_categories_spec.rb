require "rails_helper"
require "action_view/record_identifier"

RSpec.describe "Habit categories", type: :system do
  include ActionView::RecordIdentifier
  let(:user) { create(:user, password: "Password123!") }

  before do
    driven_by(:rack_test)

    visit sign_in_path
    fill_in "Correo electrónico", with: user.email
    fill_in "Contraseña", with: "Password123!"
    click_button "Iniciar sesión"
  end

  # [REQ-HAB-003, REQ-I18N-001]
  it "allows creating and renaming a category" do
    visit habit_categories_path

    fill_in "Nombre", with: "Alimentación"
    click_button "Crear categoría"

    expect(page).to have_content("Alimentación")

    click_link "Editar", match: :first
    fill_in "Nombre", with: "Nutrición"
    click_button "Actualizar categoría"

    expect(page).to have_content("Nutrición")
  end

  # [REQ-HAB-003, REQ-I18N-001]
  it "blocks deletion when category has habits" do
    category = HabitCategory.create!(user: user, name: "Salud Física", name_normalized: "salud física")
    UserHabit.create!(
      user: user,
      habit_category: category,
      name: "Agua",
      name_normalized: "agua",
      active: true
    )

    visit habit_categories_path

    within("##{dom_id(category)}") do
      click_button "Eliminar"
    end

    expect(page).to have_content(
      I18n.t("activerecord.errors.models.habit_category.attributes.base.cannot_delete_with_habits")
    )
    expect(page).to have_content("Salud Física")
  end

  # [REQ-HAB-003, REQ-I18N-001]
  it "allows deleting an empty category" do
    HabitCategory.create!(user: user, name: "Emocional", name_normalized: "emocional")

    visit habit_categories_path
    click_button "Eliminar", match: :first

    expect(page).not_to have_content("Emocional")
  end
end

