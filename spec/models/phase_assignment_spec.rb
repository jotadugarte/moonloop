# frozen_string_literal: true

require "rails_helper"

RSpec.describe PhaseAssignment, type: :model do
  let(:user) { create(:user, password: "Password123!") }
  let(:menu) { Menu.create!(user: user, name: "Semana") }

  # [REQ-MENU-003]
  it "rejects end_week before start_week" do
    a = described_class.new(user: user, menu: menu, start_week: 5, end_week: 3)
    expect(a).not_to be_valid
    expect(a.errors.added?(:end_week, :before_start_week)).to eq(true)
  end

  # [REQ-MENU-003]
  it "rejects overlapping week ranges for the same user" do
    described_class.create!(user: user, menu: menu, start_week: 1, end_week: 4)
    other_menu = Menu.create!(user: user, name: "Otro")
    dup = described_class.new(user: user, menu: other_menu, start_week: 3, end_week: 6)
    expect(dup).not_to be_valid
    expect(dup.errors.added?(:base, :range_overlap)).to eq(true)
  end

  # [REQ-MENU-003]
  it "allows adjacent ranges (no overlap)" do
    described_class.create!(user: user, menu: menu, start_week: 1, end_week: 4)
    other_menu = Menu.create!(user: user, name: "Otro")
    ok = described_class.create!(user: user, menu: other_menu, start_week: 5, end_week: 8)
    expect(ok).to be_persisted
  end

  # [REQ-MENU-003]
  it "rejects a menu that belongs to another user" do
    other = create(:user, password: "Password123!")
    foreign_menu = Menu.create!(user: other, name: "Ajeno")
    a = described_class.new(user: user, menu: foreign_menu, start_week: 1, end_week: 2)
    expect(a).not_to be_valid
    expect(a.errors.added?(:menu_id, :must_match_user)).to eq(true)
  end
end
