# frozen_string_literal: true

require "rails_helper"

RSpec.describe "MenuEntry ownership rules", type: :model do
  # [REQ-MENU-001, REQ-MENU-002]
  it "rejects referencing another user's dish" do
    owner = create(:user)
    other = create(:user)

    menu = Menu.create!(user: owner, name: "Semana propia")
    foreign_dish = Dish.create!(user: other, name: "Plato ajeno")

    entry = MenuEntry.new(
      menu: menu,
      dish: foreign_dish,
      weekday: 3,
      meal_type: "almuerzo",
      freeform_text: nil
    )

    expect(entry).not_to be_valid
    expect(entry.errors[:dish_id]).to be_present
  end
end
