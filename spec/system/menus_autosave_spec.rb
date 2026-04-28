# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Menus autosave", type: :system do
  before do
    driven_by(:selenium_chrome_headless)
  end

  include System::RegistrationHelpers

  # [REQ-MENU-001, REQ-MENU-002]
  it "filters dish options by name while keeping meal-type groups, then autosaves the slot" do
    register_user_in_browser(email: "menu-dish-filter@example.com")

    visit new_dish_path
    fill_in I18n.t("dishes.form.name_label"), with: "Café con leche"
    select I18n.t("menus.meal_types.desayuno"), from: I18n.t("dishes.form.meal_type_label")
    click_button I18n.t("dishes.form.create_submit")

    visit new_dish_path
    fill_in I18n.t("dishes.form.name_label"), with: "Ensalada simple"
    select I18n.t("menus.meal_types.almuerzo"), from: I18n.t("dishes.form.meal_type_label")
    click_button I18n.t("dishes.form.create_submit")

    visit new_dish_path
    fill_in I18n.t("dishes.form.name_label"), with: "Sopa rápida"
    select I18n.t("menus.meal_types.cena"), from: I18n.t("dishes.form.meal_type_label")
    click_button I18n.t("dishes.form.create_submit")

    user = User.find_by!(email: "menu-dish-filter@example.com")
    cafe = Dish.find_by!(user: user, name: "Café con leche")

    visit menus_path
    fill_in I18n.t("menus.index.name_label"), with: "Semana filtro"
    click_button I18n.t("menus.index.create_submit")
    expect(page).to have_current_path(%r{^/menus/\d+/edit$})

    within(%([data-test="menu-entry-slot"][data-weekday="0"][data-meal-type="desayuno"])) do
      find(%([data-test="dish-picker-filter"])).fill_in(with: "cafe")
      expect(page).to have_css(%([data-test="dish-picker-group"][data-meal-type="desayuno"]), visible: true)
      find(%([data-test="dish-picker-option"][data-dish-id="#{cafe.id}"])).click
      expect(page).to have_css(%(img[data-test="menu-slot-preview"]))
    end
  end

  # [REQ-MENU-001]
  it "autosaves a slot when selecting a recipe (no explicit save click)" do
    register_user_in_browser(email: "menu-autosave@example.com")

    visit new_dish_path
    fill_in I18n.t("dishes.form.name_label"), with: "Ensalada rápida"
    click_button I18n.t("dishes.form.create_submit")

    visit menus_path
    fill_in I18n.t("menus.index.name_label"), with: "Semana autosave"
    click_button I18n.t("menus.index.create_submit")
    expect(page).to have_current_path(%r{^/menus/\d+/edit$})

    within(%([data-test="menu-entry-slot"][data-weekday="0"][data-meal-type="desayuno"])) do
      select "Ensalada rápida", from: I18n.t("menus.slots.dish_pick_label")
    end

    # Wait for the Turbo autosave response (slot re-render).
    within(%([data-test="menu-entry-slot"][data-weekday="0"][data-meal-type="desayuno"])) do
      expect(page).to have_css(%(img[data-test="menu-slot-preview"]))
    end

    visit current_path

    within(%([data-test="menu-entry-slot"][data-weekday="0"][data-meal-type="desayuno"])) do
      expect(page).to have_select(I18n.t("menus.slots.dish_pick_label"), selected: "Ensalada rápida")
    end
  end

  # [REQ-MENU-001]
  it "autosaves freeform text on blur when freeform is enabled" do
    register_user_in_browser(email: "menu-freeform-autosave@example.com")

    visit edit_profile_path
    check I18n.t("profiles.edit.allow_menu_freeform")
    click_button I18n.t("profiles.edit.submit")
    expect(page).to have_content(I18n.t("profiles.update.success"))

    visit new_dish_path
    fill_in I18n.t("dishes.form.name_label"), with: "Avena"
    click_button I18n.t("dishes.form.create_submit")

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
