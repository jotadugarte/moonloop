# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Recipes CRUD", type: :system do
  let(:user) { create(:user, password: "Password123!") }

  def sign_in_as_user
    visit sign_in_path
    fill_in "Correo electrónico", with: user.email
    fill_in "Contraseña", with: "Password123!"
    click_button "Iniciar sesión"
  end

  # [REQ-MENU-002]
  it "creates a recipe and shows it with image on the detail page" do
    driven_by(:rack_test)
    sign_in_as_user
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

  # [REQ-MENU-002]
  context "when JS is enabled (image preview on new recipe)" do
    before do
      driven_by(:selenium_chrome_headless)
    end

    it "shows a client-side preview after attaching a raster image before submit" do
      sign_in_as_user
      visit new_recipe_path
      fill_in "Nombre", with: "Plato previo"
      png = Rails.root.join("spec/fixtures/files/recipe_test_1x1.png")
      attach_file "recipe[image]", png, make_visible: true

      alt_text = I18n.t("recipes.form.image_preview_alt")
      expect(page).to have_css(%([data-test="recipe-image-preview"] img[alt="#{alt_text}"]), visible: true)
      preview_src = find(%([data-test="recipe-image-preview"] img))[:src]
      expect(preview_src).to start_with("blob:")
    end
  end
end
