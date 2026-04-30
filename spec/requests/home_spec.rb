# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Home", type: :request do
  let(:user) { create(:user, password: "Password123!") }

  before do
    post sign_in_path, params: { email: user.email, password: "Password123!" }
  end

  # [REQ-EXR-003]
  it "exposes Mi Día, menus, dishes, exercise routines, and plans" do
    get root_path

    expect(response).to have_http_status(:ok)
    expect(response.body).to include(my_day_path)
    expect(response.body).to include(menus_path)
    expect(response.body).to include(dishes_path)
    expect(response.body).to include(exercise_routines_path)
    expect(response.body).to include(plans_path)
    expect(response.body).not_to include(user_phases_path)
  end

  it "includes reusable phases link when MOONLOOP_SHOW_USER_PHASES_NAV is enabled" do
    prev = Rails.application.config.x.show_user_phases_navigation
    Rails.application.config.x.show_user_phases_navigation = true
    get root_path
    expect(response.body).to include(user_phases_path)
  ensure
    Rails.application.config.x.show_user_phases_navigation = prev
  end
end
