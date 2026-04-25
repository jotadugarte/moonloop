# frozen_string_literal: true

module System
  module RegistrationHelpers
    # Selenium hits Puma on another DB connection; transactional fixtures hide `create(:user)` from the server.
    def register_user_in_browser(email:)
      visit sign_up_path
      fill_in I18n.t("activerecord.attributes.user.email"), with: email
      fill_in I18n.t("activerecord.attributes.user.password"), with: "Password123!"
      fill_in I18n.t("activerecord.attributes.user.password_confirmation"), with: "Password123!"
      select_user_birth_date(page, year: 1990, month: 5, day: 15)
      fill_in I18n.t("activerecord.attributes.user.height_cm"), with: "175"
      find("select[name='user[timezone]']").find("option[value='America/Santiago']").select_option
      click_button I18n.t("registrations.new.submit")
      expect(page).to have_content(I18n.t("registrations.create.signed_up"))
    end
  end
end

