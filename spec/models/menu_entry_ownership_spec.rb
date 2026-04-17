# frozen_string_literal: true

require "rails_helper"

RSpec.describe "MenuEntry ownership rules", type: :model do
  # [REQ-MENU-001, REQ-MENU-002]
  it "rejects referencing another user's recipe" do
    owner = create(:user)
    other = create(:user)

    menu = Menu.create!(user: owner, name: "Semana propia")
    foreign_recipe = Recipe.create!(user: other, name: "Receta ajena")

    entry = MenuEntry.new(
      menu: menu,
      recipe: foreign_recipe,
      weekday: 3,
      meal_type: "almuerzo",
      freeform_text: nil
    )

    expect(entry).not_to be_valid
    expect(entry.errors[:recipe_id]).to be_present
  end
end
