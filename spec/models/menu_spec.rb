# frozen_string_literal: true

require "rails_helper"

RSpec.describe Menu, type: :model do
  let(:user) { create(:user) }

  # [REQ-MENU-001] — name uniqueness per user (parity ExerciseRoutine / future REQ-MENU-006 adoption)
  it "rejects a second menu with the same normalized name for the same user" do
    Menu.create!(user: user, name: "Semana A")
    dup = Menu.new(user: user, name: "  semana a ")
    expect(dup).not_to be_valid
    expect(dup.errors.added?(:name, :taken)).to eq(true)
  end

  # [REQ-MENU-001]
  it "allows the same display name for different users" do
    other = create(:user)
    Menu.create!(user: user, name: "Única")
    other_menu = Menu.new(user: other, name: "Única")
    expect(other_menu).to be_valid
  end
end
