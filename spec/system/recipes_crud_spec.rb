# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Recipes CRUD", type: :system do
  let(:user) { create(:user, password: "Password123!") }

  before do
    driven_by(:rack_test)

    visit sign_in_path
    fill_in "Correo electrónico", with: user.email
    fill_in "Contraseña", with: "Password123!"
    click_button "Iniciar sesión"
  end

  # [REQ-MENU-002]
  it "creates a recipe and shows it with image on the detail page" do
    visit new_recipe_path

    fill_in "Nombre", with: "Batido verde"
    fill_in "Instrucciones", with: "Licuar espinaca y plátano."
    attach_file "recipe[image]", Rails.root.join("spec/fixtures/files/recipe_test.svg")
    check "Compartir en el catálogo público"

    click_button "Crear receta"

    expect(page).to have_css("h1", text: "Batido verde")
    expect(page).to have_content("Licuar espinaca")
    expect(page).to have_css('img[alt="Batido verde"]')
    expect(page).to have_content("Visible en el catálogo público")
  end
end
