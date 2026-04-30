# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Mi Día shortcut to menus and phase plan", type: :system do
  let(:user) { create(:user, password: "Password123!", timezone: "Etc/UTC") }

  before do
    driven_by(:rack_test)
    visit sign_in_path
    fill_in "Correo electrónico", with: user.email
    fill_in "Contraseña", with: "Password123!"
    click_button "Iniciar sesión"
  end

  # [REQ-MENU-003] entry point from Mi Día to phase plan / menus area
  it "shows a shortcut below the day content and navigates to the phase plan" do
    skip "Temporarily hidden per user request"
    visit my_day_path

    expect(page).to have_css('[data-test="my-day-phases-shortcut"]')
    expect(page).to have_content(I18n.t("my_day.show.phases_shortcut_heading"))

    click_link I18n.t("my_day.show.phases_shortcut_link")

    expect(page).to have_current_path(phase_path)
    expect(page).to have_content(I18n.t("phases.show.heading"))
  end
end
