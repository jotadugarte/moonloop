# frozen_string_literal: true

require "rails_helper"

RSpec.describe Phases::ResolveActiveMenu do
  let(:user) { create(:user, password: "Password123!") }
  let(:menu_a) { Menu.create!(user: user, name: "A") }
  let(:menu_b) { Menu.create!(user: user, name: "B") }

  # [REQ-MENU-003]
  it "returns nil when week_index is nil" do
    expect(described_class.call(user: user, week_index: nil)).to be_nil
  end

  # [REQ-MENU-003]
  it "returns the menu whose range covers the week index" do
    PhaseAssignment.create!(user: user, menu: menu_a, start_week: 1, end_week: 4)
    PhaseAssignment.create!(user: user, menu: menu_b, start_week: 5, end_week: 8)

    expect(described_class.call(user: user, week_index: 3)).to eq(menu_a)
    expect(described_class.call(user: user, week_index: 5)).to eq(menu_b)
  end

  # [REQ-MENU-003]
  it "returns nil when no assignment covers the week (gap)" do
    PhaseAssignment.create!(user: user, menu: menu_a, start_week: 1, end_week: 2)
    expect(described_class.call(user: user, week_index: 10)).to be_nil
  end
end
