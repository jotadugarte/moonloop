require "rails_helper"

RSpec.describe "Profile", type: :system do
  let(:user) { create(:user, password: "Password123!", timezone: "America/New_York", date_of_birth: "1990-01-01") }

  before do
    driven_by(:rack_test)

    visit sign_in_path
    fill_in I18n.t("activerecord.attributes.user.email"), with: user.email
    fill_in I18n.t("activerecord.attributes.user.password"), with: "Password123!"
    click_button I18n.t("sessions.new.submit")
  end

  # [REQ-AUTH-002, REQ-I18N-001, REQ-PROF-001]
  it "allows users to update profile attributes but not height" do
    visit edit_profile_path

    expect(page).not_to have_field("Height")
    expect(page).not_to have_field("Altura (cm)")

    fill_in I18n.t("activerecord.attributes.user.date_of_birth"), with: "1985-11-20"
    select "(GMT+01:00) Madrid", from: I18n.t("activerecord.attributes.user.timezone")
    click_button I18n.t("profiles.edit.submit")

    expect(page).to have_content(I18n.t("profiles.update.success"))

    user.reload
    expect(user.date_of_birth.to_s).to eq("1985-11-20")
    expect(user.timezone).to eq("Europe/Madrid")
    expect(user.body_unit_system).to eq("metric")
  end

  # [REQ-PROF-003, REQ-AUTH-002]
  it "permite actualizar la preferencia de unidades sin exponer altura editable" do
    visit edit_profile_path

    expect(page).not_to have_field("Altura (cm)")

    choose "user_body_unit_system_imperial_us"
    click_button I18n.t("profiles.edit.submit")

    expect(page).to have_content(I18n.t("profiles.update.success"))
    expect(user.reload.body_unit_system).to eq("imperial_us")
  end

  # [REQ-PROF-001, REQ-AUTH-002]
  it "renders all profile form inputs with associated <label> elements" do
    visit edit_profile_path

    expect(page).to have_field(I18n.t("activerecord.attributes.user.date_of_birth"))
    expect(page).to have_field(I18n.t("activerecord.attributes.user.timezone"))
    expect(page).not_to have_field(I18n.t("activerecord.attributes.user.height_cm"))
  end

  # [REQ-PROF-001]
  it "returns 422 and renders validation errors with role=alert when profile update fails" do
    visit edit_profile_path

    fill_in I18n.t("activerecord.attributes.user.date_of_birth"), with: ""
    click_button I18n.t("profiles.edit.submit")

    expect(page.driver.status_code).to eq(422)
    expect(page).to have_css("[role='alert']")
  end
end
