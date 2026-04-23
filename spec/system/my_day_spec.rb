require "rails_helper"

RSpec.describe "Mi Día view", type: :system do
  let(:user) { create(:user, password: "Password123!", timezone: "America/Mexico_City") }

  before do
    driven_by(:rack_test)

    visit sign_in_path
    fill_in "Correo electrónico", with: user.email
    fill_in "Contraseña", with: "Password123!"
    click_button "Iniciar sesión"
  end

  # [REQ-DAY-001]
  it "displays the local date prominently on the page" do
    visit my_day_path

    local_today = Time.find_zone!(user.timezone).today
    expect(page).to have_css("[data-test='my-day-local-date']")
    within("[data-test='my-day-local-date']") do
      expect(page).to have_text(I18n.l(local_today, format: :long))
    end
  end

  # [REQ-DAY-001]
  it "renders the date picker input with an associated <label>" do
    visit my_day_path

    expect(page).to have_field(I18n.t("my_day.show.date_label"))
  end
end
