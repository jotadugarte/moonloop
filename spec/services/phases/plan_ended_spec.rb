# frozen_string_literal: true

require "rails_helper"

RSpec.describe Phases::PlanEnded do
  let(:user) { create(:user, password: "Password123!") }
  let(:menu) { Menu.create!(user: user, name: "M") }

  # [REQ-MENU-005]
  it "is false when week_index is blank" do
    expect(described_class.call(user: user, week_index: nil)).to eq(false)
  end

  # [REQ-MENU-005]
  it "is false when there are no assignments" do
    expect(described_class.call(user: user, week_index: 5)).to eq(false)
  end

  # [REQ-MENU-005]
  it "is false when the week is still inside the last range" do
    PhaseAssignment.create!(user: user, menu: menu, start_week: 1, end_week: 4)
    expect(described_class.call(user: user, week_index: 4)).to eq(false)
  end

  # [REQ-MENU-005]
  it "is true when the current week is past the maximum assigned end_week" do
    PhaseAssignment.create!(user: user, menu: menu, start_week: 1, end_week: 4)
    expect(described_class.call(user: user, week_index: 5)).to eq(true)
  end
end
