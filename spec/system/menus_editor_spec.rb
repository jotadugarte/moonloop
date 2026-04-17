# frozen_string_literal: true

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
end
