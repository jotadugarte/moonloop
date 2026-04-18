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
end
