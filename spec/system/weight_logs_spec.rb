# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Weight logs", type: :system do
  let(:user) { create(:user, password: "Password123!", timezone: "Etc/UTC", height_cm: 175) }

  before do
    driven_by(:rack_test)
    visit sign_in_path
    fill_in "Correo electrónico", with: user.email
    fill_in "Contraseña", with: "Password123!"
    click_button "Iniciar sesión"
  end

  # [REQ-WGT-002] [REQ-WGT-003]
  it "sets the page title on new and history from i18n" do
    visit new_weight_log_path
    expect(page).to have_title(I18n.t("weight_logs.new.title"))

    visit weight_logs_path
    expect(page).to have_title(I18n.t("weight_logs.index.title"))
  end

  # [REQ-WGT-002, REQ-WGT-004]
  it "registra en libras y muestra el historial en la preferencia actual" do
    user.update!(body_unit_system: "imperial_us")
    visit new_weight_log_path

    fill_in "weight_log_weight_lb", with: "154.3"
    fill_in "weight_log_logged_at", with: "2026-04-16T10:30"
    click_button "Guardar"

    expect(page).to have_content(I18n.t("weight_logs.flash.created"))
    expect(user.reload.weight_logs.count).to eq(1)
    expect(user.current_weight_kg).to be_within(0.05).of(70.0)

    visit weight_logs_path
    expect(page).to have_content("154.3")
  end
end
