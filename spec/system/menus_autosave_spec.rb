# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Menus autosave", type: :system do
  before do
    driven_by(:selenium_chrome_headless)
  end

  # Selenium hits Puma on another DB connection; transactional fixtures hide `create(:user)` from the server.
  def register_user_in_browser(email:)
    visit sign_up_path
    fill_in I18n.t("activerecord.attributes.user.email"), with: email
    fill_in I18n.t("activerecord.attributes.user.password"), with: "Password123!"
    fill_in I18n.t("activerecord.attributes.user.password_confirmation"), with: "Password123!"
    select_user_birth_date(page, year: 1990, month: 5, day: 15)
    fill_in I18n.t("activerecord.attributes.user.height_cm"), with: "175"
    find("select[name='user[timezone]']").find("option[value='America/Santiago']").select_option
    click_button I18n.t("registrations.new.submit")
    expect(page).to have_content(I18n.t("registrations.create.signed_up"))
  end

  # [REQ-MENU-001]
  it "autosaves a slot when selecting a recipe (no explicit save click)" do
    register_user_in_browser(email: "menu-autosave@example.com")

    visit new_recipe_path
    fill_in "Nombre", with: "Ensalada rápida"
    click_button "Crear receta"

    visit menus_path
    fill_in I18n.t("menus.index.name_label"), with: "Semana autosave"
    click_button I18n.t("menus.index.create_submit")

    menu = Menu.find_by!(name: "Semana autosave")

    visit edit_menu_path(menu)

    within(%([data-test="menu-entry-slot"][data-weekday="0"][data-meal-type="desayuno"])) do
      select "Ensalada rápida", from: I18n.t("menus.slots.recipe_pick_label")
    end

    visit edit_menu_path(menu)

    within(%([data-test="menu-entry-slot"][data-weekday="0"][data-meal-type="desayuno"])) do
      expect(page).to have_select(I18n.t("menus.slots.recipe_pick_label"), selected: "Ensalada rápida")
    end
  end
end

