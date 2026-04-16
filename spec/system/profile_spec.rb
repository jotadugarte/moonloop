require 'rails_helper'

RSpec.describe 'Profile Editing', type: :system do
  let(:user) { create(:user, password: "Password123!", timezone: "America/New_York", date_of_birth: "1990-01-01") }

  before do
    driven_by(:rack_test)

    # Log in using standard auth-zero forms
    visit sign_in_path
    fill_in 'Correo electrónico', with: user.email
    fill_in 'Contraseña', with: 'Password123!'
    click_button 'Iniciar sesión'
  end

  # [REQ-AUTH-002, REQ-I18N-001, REQ-PROF-001]
  it 'allows users to update profile attributes but not height' do
    # We will build this route during the GREEN phase
    visit edit_profile_path

    # Height should be completely excluded from the UI since it is immutable
    expect(page).not_to have_field('Height')
    expect(page).not_to have_field('Altura (cm)')

    # Date of birth and Timezone are editable
    fill_in 'Fecha de nacimiento', with: '1985-11-20'
    fill_in 'Zona horaria', with: 'Europe/Madrid'

    click_button 'Actualizar perfil'

    expect(page).to have_content('Perfil actualizado correctamente')

    user.reload
    expect(user.date_of_birth.to_s).to eq('1985-11-20')
    expect(user.timezone).to eq('Europe/Madrid')
  end
end
