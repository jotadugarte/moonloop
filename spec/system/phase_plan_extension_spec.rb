# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Phase plan extension (REQ-MENU-005)", type: :system do
  let(:anchor) { Date.new(2026, 1, 1) }
  let(:user) { create(:user, password: "Password123!", timezone: "Etc/UTC", phase_one_starts_on: anchor) }
  let(:menu) { Menu.create!(user: user, name: "Menú semanal") }

  before do
    driven_by(:rack_test)
    PhaseAssignment.create!(user: user, menu: menu, start_week: 1, end_week: 4)

    visit sign_in_path
    fill_in "Correo electrónico", with: user.email
    fill_in "Contraseña", with: "Password123!"
    click_button "Iniciar sesión"
  end

  # [REQ-MENU-005]
  it "shows the plan-ended prompt past the last range and repeats the last block in one click" do
    week5_midday = Time.find_zone("Etc/UTC").local(2026, 1, 29, 12, 0, 0)
    travel_to(week5_midday) do
      visit phase_path

      expect(page).to have_css('[data-test="phase-plan-ended-banner"]')
      expect(page).to have_link(href: new_phase_assignment_path)

      expect {
        click_button I18n.t("phases.show.repeat_last_assignment")
      }.to change { user.reload.phase_assignments.count }.by(1)

      expect(page).to have_current_path(phase_path)
      added = user.phase_assignments.order(:start_week).last
      expect(added.start_week).to eq(5)
      expect(added.end_week).to eq(8)
      expect(added.menu).to eq(menu)
    end
  end
end
