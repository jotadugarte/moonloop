require 'rails_helper'

RSpec.describe 'User Registration', type: :system do
  before do
    driven_by(:rack_test)
  end

  it 'allows the user to sign up by providing profile fields' do
    visit sign_up_path

    fill_in 'Email', with: 'test@example.com'
    fill_in 'Password', with: 'Password123!'
    fill_in 'Password confirmation', with: 'Password123!'
    
    fill_in 'Date of birth', with: '1990-05-15'
    fill_in 'Height cm', with: '175'
    
    # Normally JS automates this part in front-end, we simulate normal submission
    fill_in 'Timezone', with: 'America/Santiago'

    click_button 'Sign up'

    # Depends on what authentication-zero redirects to by default
    expect(page).to have_content('Welcome') # or whatever flash/path is expected
    
    user = User.last
    expect(user.email).to eq('test@example.com')
    expect(user.height_cm).to eq(175)
    expect(user.timezone).to eq('America/Santiago')
  end

  it 'shows an error when profile fields are missing' do
    visit sign_up_path
    
    fill_in 'Email', with: 'incomplete@example.com'
    fill_in 'Password', with: 'Password123!'
    fill_in 'Password confirmation', with: 'Password123!'
    click_button 'Sign up'

    expect(page).to have_content("Date of birth can't be blank")
    expect(page).to have_content("Height cm can't be blank")
  end
end
