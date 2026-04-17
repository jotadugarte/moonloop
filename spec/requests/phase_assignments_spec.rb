# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Phase assignments", type: :request do
  let(:user) { create(:user, password: "Password123!", timezone: "Etc/UTC") }
  let(:menu) { Menu.create!(user: user, name: "Menú A") }

  before do
    post sign_in_path, params: { email: user.email, password: "Password123!" }
  end

  # [REQ-MENU-003]
  it "creates an assignment" do
    post phase_assignments_path,
      params: { phase_assignment: { menu_id: menu.id, start_week: 1, end_week: 4 } }

    expect(response).to have_http_status(:found)
    expect(PhaseAssignment.find_by!(user: user, menu: menu).start_week).to eq(1)
  end

  # [REQ-MENU-003]
  it "rejects overlapping assignments" do
    PhaseAssignment.create!(user: user, menu: menu, start_week: 1, end_week: 4)
    other = Menu.create!(user: user, name: "Menú B")

    post phase_assignments_path,
      params: { phase_assignment: { menu_id: other.id, start_week: 3, end_week: 6 } }

    expect(response).to have_http_status(:unprocessable_content)
    expect(PhaseAssignment.where(menu: other).count).to eq(0)
  end

  # [REQ-MENU-003]
  it "forbids editing another user's assignment" do
    other = create(:user, password: "Password123!")
    foreign = PhaseAssignment.create!(
      user: other,
      menu: Menu.create!(user: other, name: "X"),
      start_week: 1,
      end_week: 2
    )

    get edit_phase_assignment_path(foreign)

    expect(response).to have_http_status(:not_found)
  end
end
