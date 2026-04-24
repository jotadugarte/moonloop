require 'rails_helper'

RSpec.describe 'User Registration', type: :system do
  before do
    driven_by(:rack_test)
  end

  # [REQ-AUTH-001, REQ-I18N-001, REQ-PROF-001]
  it 'allows the user to sign up by providing profile fields' do
    visit sign_up_path

    fill_in 'Correo electrónico', with: 'test@example.com'
    fill_in 'Contraseña', with: 'Password123!'
    fill_in 'Confirmación de contraseña', with: 'Password123!'

    fill_in 'Fecha de nacimiento', with: '1990-05-15'
    fill_in 'Altura (cm)', with: '175'

    # Normally JS automates this part in front-end, we simulate normal submission
    find("select[name='user[timezone]']").find("option[value='America/Santiago']").select_option

    click_button 'Registrarse'

    expect(page).to have_content(I18n.t("registrations.create.signed_up"))

    user = User.last
    expect(user.email).to eq('test@example.com')
    expect(user.height_cm).to eq(175)
    expect(user.timezone).to eq('America/Santiago')
    expect(user.body_unit_system).to eq("metric")
  end

  # [REQ-PROF-003, REQ-AUTH-001]
  it "registra con altura imperial y persiste cm canónico y preferencia imperial_us" do
    visit sign_up_path

    fill_in "Correo electrónico", with: "imperial@example.com"
    fill_in "Contraseña", with: "Password123!"
    fill_in "Confirmación de contraseña", with: "Password123!"
    fill_in "Fecha de nacimiento", with: "1990-05-15"

    choose "user_body_unit_system_imperial_us"
    fill_in "user_registration_height_feet", with: "5"
    fill_in "user_registration_height_inches", with: "7"

    find("select[name='user[timezone]']").find("option[value='America/Santiago']").select_option
    click_button "Registrarse"

    expect(page).to have_content(I18n.t("registrations.create.signed_up"))

    user = User.order(:id).last
    expect(user.email).to eq("imperial@example.com")
    expect(user.body_unit_system).to eq("imperial_us")
    expect(user.height_cm).to eq(170)
  end

  # [REQ-PROF-003]
  it "muestra error de altura cuando la conversión imperial queda fuera de rango" do
    visit sign_up_path

    fill_in "Correo electrónico", with: "badht@example.com"
    fill_in "Contraseña", with: "Password123!"
    fill_in "Confirmación de contraseña", with: "Password123!"
    fill_in "Fecha de nacimiento", with: "1990-05-15"

    choose "user_body_unit_system_imperial_us"
    fill_in "user_registration_height_feet", with: "1"
    fill_in "user_registration_height_inches", with: "0"

    find("select[name='user[timezone]']").find("option[value='America/Santiago']").select_option
    click_button "Registrarse"

    expect(page).to have_css("#registration-form-errors[role='alert']")
    msg = I18n.t("activerecord.errors.messages.greater_than_or_equal_to", count: 50)
    expect(page).to have_content(msg)
  end

  # [REQ-I18N-001, REQ-PROF-001]
  it 'shows an error when profile fields are missing' do
    visit sign_up_path

    fill_in 'Correo electrónico', with: 'incomplete@example.com'
    fill_in 'Contraseña', with: 'Password123!'
    fill_in 'Confirmación de contraseña', with: 'Password123!'
    click_button 'Registrarse'

    blank = I18n.t("activerecord.errors.messages.blank")
    expect(page).to have_content("#{I18n.t('activerecord.attributes.user.date_of_birth')} #{blank}")
    expect(page).to have_content("#{I18n.t('activerecord.attributes.user.height_cm')} #{blank}")
  end

  # [REQ-PROF-001, REQ-I18N-001]
  it "displays the correct label for imperial system and uses a timezone select" do
    visit sign_up_path

    # Timezone should be a select field, not a text input
    expect(page).to have_select('user[timezone]')

    # The radio button label should use "Imperial" instead of "Estados Unidos"
    expect(page).to have_content("Imperial (pies / pulgadas)")
  end

  # [REQ-PROF-003]
  context "with JS enabled (visibility toggle)" do
    before do
      driven_by(:selenium_chrome_headless)
    end

    it "toggles height inputs visibility based on unit system selection" do
      visit sign_up_path

      # By default, metric is selected, so cm input should be visible and imperial hidden
      expect(page).to have_field('Altura (cm)', visible: true)
      expect(page).to have_field('user_registration_height_feet', visible: false)
      expect(page).to have_field('user_registration_height_inches', visible: false)

      # Change to imperial
      choose "user_body_unit_system_imperial_us"

      expect(page).to have_field('Altura (cm)', visible: false)
      expect(page).to have_field('user_registration_height_feet', visible: true)
      expect(page).to have_field('user_registration_height_inches', visible: true)

      # Change back to metric
      choose "user_body_unit_system_metric"

      expect(page).to have_field('Altura (cm)', visible: true)
      expect(page).to have_field('user_registration_height_feet', visible: false)
      expect(page).to have_field('user_registration_height_inches', visible: false)
    end
  end
end
