# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Exercise routines", type: :system do
  let(:user) { create(:user, password: "Password123!", timezone: "Etc/UTC") }

  before do
    driven_by(:rack_test)
    visit sign_in_path
    fill_in "Correo electrónico", with: user.email
    fill_in "Contraseña", with: "Password123!"
    click_button "Iniciar sesión"
  end

  # [REQ-EXR-001] smoke: server-rendered list + create form
  it "shows the routines index with a create form" do
    visit exercise_routines_path

    expect(page).to have_content(I18n.t("exercise_routines.index.title"))
    expect(page).to have_field(I18n.t("exercise_routines.index.name_label"))
  end
end
