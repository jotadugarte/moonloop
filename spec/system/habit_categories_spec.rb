require "rails_helper"
require "action_view/record_identifier"

# REQ-HABITS-007: Users can manage categories (create, rename, delete) with deletion blocked when referenced.
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

    expect(page).to have_content("cannot delete")
    expect(page).to have_content("Salud Física")
  end

  it "allows deleting an empty category" do
    HabitCategory.create!(user: user, name: "Emocional", name_normalized: "emocional")

    visit habit_categories_path
    click_button "Eliminar", match: :first

    expect(page).not_to have_content("Emocional")
  end
end

