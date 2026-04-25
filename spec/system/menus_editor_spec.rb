# frozen_string_literal: true

require "stringio"

require "rails_helper"

RSpec.describe "Menus editor", type: :system do
  let(:user) { create(:user, password: "Password123!") }

  before do
    driven_by(:rack_test)

    visit sign_in_path
    fill_in "Correo electrónico", with: user.email
    fill_in "Contraseña", with: "Password123!"
    click_button "Iniciar sesión"
  end

  # [REQ-MENU-001, REQ-I18N-001]
  it "renders a 7x4 grid of meal slots (sparse entries)" do
    menu = Menu.create!(user: user, name: "Semana prueba")

    visit "/menus/#{menu.id}/edit"

    Menus::MealType::KEYS.each do |meal_type|
      (0..6).each do |weekday|
        expect(page).to have_css(%([data-test="menu-entry-slot"][data-weekday="#{weekday}"][data-meal-type="#{meal_type}"]))
      end
    end
  end

  # [REQ-MENU-001]
  it "redirects to the editor after creating a menu from the index" do
    visit "/menus"

    fill_in "Nombre", with: "Nueva semana"
    click_button "Crear menú"

    menu = Menu.find_by!(user: user, name: "Nueva semana")
    expect(page).to have_current_path(edit_menu_path(menu))
  end

  # [REQ-MENU-002]
  it "shows a meal-type fallback preview when the slot recipe has no image" do
    menu = Menu.create!(user: user, name: "Con receta")
    recipe = Recipe.create!(user: user, name: "Ensalada")
    MenuEntry.create!(
      menu: menu,
      recipe: recipe,
      weekday: 5,
      meal_type: "cena",
      freeform_text: nil
    )

    visit "/menus/#{menu.id}/edit"

    within(%([data-test="menu-entry-slot"][data-weekday="5"][data-meal-type="cena"])) do
      expect(page).to have_css(%(img[data-test="menu-slot-preview"][data-preview-kind="fallback"][src*="fallback_cena"]))
    end
  end

  # [REQ-MENU-002]
  it "shows the recipe upload in the slot preview when the recipe has an image" do
    menu = Menu.create!(user: user, name: "Menú foto")
    recipe = Recipe.create!(user: user, name: "Tortilla")
    recipe.image.attach(
      io: StringIO.new(File.read(Rails.root.join("spec/fixtures/files/recipe_test.svg"))),
      filename: "recipe_test.svg",
      content_type: "image/svg+xml"
    )
    MenuEntry.create!(
      menu: menu,
      recipe: recipe,
      weekday: 2,
      meal_type: "desayuno",
      freeform_text: nil
    )

    visit edit_menu_path(menu)

    within(%([data-test="menu-entry-slot"][data-weekday="2"][data-meal-type="desayuno"])) do
      expect(page).to have_css(%(img[data-test="menu-slot-preview"]:not([data-preview-kind="fallback"])))
      expect(page).to have_css(%(img[src*="active_storage"]))
    end
  end
end
