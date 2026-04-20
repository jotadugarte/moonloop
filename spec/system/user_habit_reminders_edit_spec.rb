# frozen_string_literal: true

require "rails_helper"

RSpec.describe "User habit reminder settings", type: :system do
  # [REQ-HAB-010]
  it "lets a user enable an email reminder with a time of day from the habit edit screen" do
    user = create(:user, password: "Password123!")
    habit = create(:user_habit, user: user, reminder_enabled: false)

    driven_by(:rack_test)

    visit sign_in_path
    fill_in "Correo electrónico", with: user.email
    fill_in "Contraseña", with: "Password123!"
    click_button "Iniciar sesión"

    visit edit_user_habit_path(habit)

    check "Activar recordatorio"
    fill_in "Hora", with: "08:30"
    check "Email"
    click_button "Guardar"

    expect(habit.reload.reminder_enabled).to be(true)
    expect(habit.reminder_time_of_day).to eq("08:30")
    expect(habit.reminder_email).to be(true)
  end
end
