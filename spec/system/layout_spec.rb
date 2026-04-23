require "rails_helper"

RSpec.describe "Application Layout", type: :system do
  let(:user) { create(:user, password: "Password123!") }

  before do
    driven_by(:rack_test)

    visit sign_in_path
    fill_in I18n.t("activerecord.attributes.user.email"), with: user.email
    fill_in I18n.t("activerecord.attributes.user.password"), with: "Password123!"
    click_button I18n.t("sessions.new.submit")
  end

  # [REQ-DAY-001, REQ-RPT-001, REQ-PROF-001]
  it "renders a semantic <nav> element with accessible links to the main sections" do
    visit my_day_path

    within("nav") do
      expect(page).to have_link(I18n.t("layout.nav.my_day"),   href: my_day_path)
      expect(page).to have_link(I18n.t("layout.nav.catalogs"), href: public_menus_path)
      expect(page).to have_link(I18n.t("layout.nav.reports"),  href: informes_path)
      expect(page).to have_link(I18n.t("layout.nav.profile"),  href: edit_profile_path)
    end
  end

  # [REQ-PLAT-001]
  it "includes a mobile viewport meta tag in the document head" do
    visit my_day_path

    expect(page).to have_css("meta[name='viewport']", visible: :hidden)
  end
end
