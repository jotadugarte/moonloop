# frozen_string_literal: true

require "rails_helper"

RSpec.describe Phases::RepeatLastPhaseAssignment do
  let(:user) { create(:user, password: "Password123!") }
  let(:menu_a) { Menu.create!(user: user, name: "A") }
  let(:menu_b) { Menu.create!(user: user, name: "B") }

  # [REQ-MENU-005]
  it "returns nil when there are no assignments" do
    expect(described_class.call(user: user)).to be_nil
  end

  # [REQ-MENU-005]
  it "appends a range with the same menu and span as the block that ends last" do
    PhaseAssignment.create!(user: user, menu: menu_a, start_week: 1, end_week: 4)
    PhaseAssignment.create!(user: user, menu: menu_b, start_week: 5, end_week: 7)

    created = described_class.call(user: user.reload)

    expect(created).to be_persisted
    expect(created.menu).to eq(menu_b)
    expect(created.start_week).to eq(8)
    expect(created.end_week).to eq(10)
  end
end
