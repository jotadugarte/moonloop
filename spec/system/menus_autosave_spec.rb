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
    expect(page).to have_current_path(%r{^/menus/\d+/edit$})

    within(%([data-test="menu-entry-slot"][data-weekday="0"][data-meal-type="desayuno"])) do
      select "Ensalada rápida", from: I18n.t("menus.slots.recipe_pick_label")
    end

    # Wait for the Turbo autosave response (slot re-render).
    within(%([data-test="menu-entry-slot"][data-weekday="0"][data-meal-type="desayuno"])) do
      expect(page).to have_css(%(img[data-test="menu-slot-preview"]))
    end

    visit current_path

    within(%([data-test="menu-entry-slot"][data-weekday="0"][data-meal-type="desayuno"])) do
      expect(page).to have_select(I18n.t("menus.slots.recipe_pick_label"), selected: "Ensalada rápida")
    end
  end

  # [REQ-MENU-001]
  it "autosaves freeform text on blur when freeform is enabled" do
    register_user_in_browser(email: "menu-freeform-autosave@example.com")

    visit edit_profile_path
    check I18n.t("profiles.edit.allow_menu_freeform")
    click_button I18n.t("profiles.edit.submit")
    expect(page).to have_content(I18n.t("profiles.update.success"))

    visit new_recipe_path
    fill_in "Nombre", with: "Avena"
    click_button "Crear receta"

    visit menus_path
    fill_in I18n.t("menus.index.name_label"), with: "Semana freeform"
    click_button I18n.t("menus.index.create_submit")
    expect(page).to have_current_path(%r{^/menus/\d+/edit$})

    within(%([data-test="menu-entry-slot"][data-weekday="1"][data-meal-type="desayuno"])) do
      fill_in I18n.t("menus.slots.freeform_label"), with: "nota rápida"
      find_field(I18n.t("menus.slots.freeform_label")).send_keys(:tab) # blur
    end

    visit current_path

    within(%([data-test="menu-entry-slot"][data-weekday="1"][data-meal-type="desayuno"])) do
      expect(page).to have_field(I18n.t("menus.slots.freeform_label"), with: "nota rápida")
    end
  end
end

