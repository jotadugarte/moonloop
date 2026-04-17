# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Phase start in-app reminder banner", type: :system do
  let(:anchor) { Date.new(2026, 6, 10) }
  let(:user) do
    create(
      :user,
      password: "Password123!",
      timezone: "Europe/Madrid",
      phase_one_starts_on: anchor,
      phase_reminder_in_app: true,
      phase_reminder_dismissed_on: nil
    )
  end

  before do
    driven_by(:rack_test)
    visit sign_in_path
    fill_in "Correo electrónico", with: user.email
    fill_in "Contraseña", with: "Password123!"
    click_button "Iniciar sesión"
  end

  # [REQ-MENU-004]
  it "shows on the anchor day, hides after dismiss, and stays hidden on revisit the same day" do
    madrid = ActiveSupport::TimeZone["Europe/Madrid"].local(2026, 6, 10, 10, 0, 0)
    travel_to(madrid) do
      visit phase_path
      expect(page).to have_css('[data-test="phase-start-reminder-banner"]')

      click_button I18n.t("phases.show.phase_start_reminder_dismiss")

      expect(page).to have_current_path(phase_path)
      expect(page).not_to have_css('[data-test="phase-start-reminder-banner"]')

      visit phase_path
      expect(page).not_to have_css('[data-test="phase-start-reminder-banner"]')
    end
  end

  # [REQ-MENU-004]
  it "does not show when in-app reminders are disabled" do
    user.update!(phase_reminder_in_app: false)
    madrid = ActiveSupport::TimeZone["Europe/Madrid"].local(2026, 6, 10, 10, 0, 0)
    travel_to(madrid) do
      visit phase_path
      expect(page).not_to have_css('[data-test="phase-start-reminder-banner"]')
    end
  end
end
