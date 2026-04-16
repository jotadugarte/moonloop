require 'rails_helper'

RSpec.describe 'Profile Editing', type: :system do
  let(:user) { create(:user, password: "Password123!", timezone: "America/New_York", date_of_birth: "1990-01-01") }

  before do
    driven_by(:rack_test)
    
    # Log in using standard auth-zero forms
    visit sign_in_path
    fill_in 'Email', with: user.email
    fill_in 'Password', with: 'Password123!'
    click_button 'Sign in'
  end

  it 'allows users to update profile attributes but not height' do
    # We will build this route during the GREEN phase
    visit edit_profile_path

    # Height should be completely excluded from the UI since it is immutable
    expect(page).not_to have_field('Height')
    expect(page).not_to have_field('Height cm')

    # Date of birth and Timezone are editable
    fill_in 'Date of birth', with: '1985-11-20'
    fill_in 'Timezone', with: 'Europe/Madrid'
    
    click_button 'Update Profile'

    expect(page).to have_content('Profile updated successfully')
    
    user.reload
    expect(user.date_of_birth.to_s).to eq('1985-11-20')
    expect(user.timezone).to eq('Europe/Madrid')
  end
end
