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
    fill_in 'Zona horaria', with: 'America/Santiago'

    click_button 'Registrarse'

    expect(page).to have_content(I18n.t("registrations.create.signed_up"))

    user = User.last
    expect(user.email).to eq('test@example.com')
    expect(user.height_cm).to eq(175)
    expect(user.timezone).to eq('America/Santiago')
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
end
