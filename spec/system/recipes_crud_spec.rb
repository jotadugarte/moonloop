# frozen_string_literal: true

require "rails_helper"
require "securerandom"

RSpec.describe "Dishes CRUD", type: :system do
  let(:user) { create(:user, password: "Password123!") }

  def sign_in_as_user
    visit sign_in_path
    fill_in "Correo electrónico", with: user.email
    fill_in "Contraseña", with: "Password123!"
    click_button "Iniciar sesión"
  end

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

  # [REQ-MENU-002]
  it "creates a dish and shows it with image on the detail page" do
    driven_by(:rack_test)
    sign_in_as_user
    visit new_dish_path

    fill_in I18n.t("dishes.form.name_label"), with: "Batido verde"
    fill_in I18n.t("dishes.form.instructions_label"), with: "Licuar espinaca y plátano."
    attach_file "dish[image]", Rails.root.join("spec/fixtures/files/recipe_test.svg")
    check I18n.t("dishes.form.public_label")

    click_button I18n.t("dishes.form.create_submit")

    expect(page).to have_css("h1", text: "Batido verde")
    expect(page).to have_content("Licuar espinaca")
    expect(page).to have_css('img[alt="Batido verde"]')
    expect(page).to have_content("Visible en el catálogo público")
  end

  # [REQ-MENU-002]
  context "when JS is enabled (image preview on new dish)" do
    before do
      driven_by(:selenium_chrome_headless)
    end

    it "shows a client-side preview after attaching a raster image before submit" do
      register_user_in_browser(email: "recipe-preview-#{SecureRandom.hex(8)}@example.com")
      visit new_dish_path
      fill_in I18n.t("dishes.form.name_label"), with: "Plato previo"
      png = Rails.root.join("spec/fixtures/files/recipe_test_1x1.png")
      attach_file "dish[image]", png, make_visible: true

      alt_text = I18n.t("dishes.form.image_preview_alt")
      expect(page).to have_css(%([data-test="dish-image-preview"] img[alt="#{alt_text}"]), visible: true)
      preview_src = find(%([data-test="dish-image-preview"] img))[:src]
      expect(preview_src).to start_with("blob:")
    end
  end
end
