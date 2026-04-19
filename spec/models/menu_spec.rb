# frozen_string_literal: true

require "rails_helper"

RSpec.describe Menu, type: :model do
  let(:user) { create(:user) }

  # [REQ-MENU-006]
  it "reflects optional source_menu and adopted_copies for catalog adoption" do
    src = Menu.reflect_on_association(:source_menu)
    expect(src.options[:class_name]).to eq("Menu")
    expect(src.options[:optional]).to eq(true)

    copies = Menu.reflect_on_association(:adopted_copies)
    expect(copies.klass).to eq(Menu)
    expect(copies.options[:dependent]).to eq(:nullify)
  end

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
