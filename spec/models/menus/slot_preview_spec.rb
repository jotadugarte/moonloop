# frozen_string_literal: true

require "base64"
require "stringio"

require "rails_helper"

RSpec.describe Menus::SlotPreview do
  let(:user) { create(:user, password: "Password123!") }
  let(:menu) { Menu.create!(user: user, name: "Semana") }
  let(:recipe) { Recipe.create!(user: user, name: "Porridge") }

  # [REQ-MENU-002]
  it "returns nil for a blank entry" do
    expect(described_class.call(entry: nil, meal_type: "desayuno")).to be_nil
  end

  # [REQ-MENU-002]
  it "returns nil when the slot has no recipe and no freeform text" do
    entry = MenuEntry.new(menu: menu, weekday: 1, meal_type: "cena", recipe: nil, freeform_text: "")
    expect(described_class.call(entry: entry, meal_type: "cena")).to be_nil
  end

  # [REQ-MENU-002]
  it "uses a meal-type fallback asset when the recipe has no image" do
    entry = MenuEntry.create!(
      menu: menu,
      recipe: recipe,
      weekday: 3,
      meal_type: "merienda",
      freeform_text: nil
    )

    result = described_class.call(entry: entry, meal_type: "merienda")
    expect(result.display).to eq(:fallback)
    expect(result.fallback_asset_path).to eq("menus/fallback_merienda.svg")
  end

  # [REQ-MENU-002]
  it "uses a meal-type fallback when only freeform text is present" do
    entry = MenuEntry.create!(
      menu: menu,
      recipe: nil,
      weekday: 4,
      meal_type: "almuerzo",
      freeform_text: "Sopa del día"
    )

    result = described_class.call(entry: entry, meal_type: "almuerzo")
    expect(result.display).to eq(:fallback)
    expect(result.fallback_asset_path).to eq("menus/fallback_almuerzo.svg")
  end

  # [REQ-MENU-002]
  it "uses the uploaded image when the recipe has an attachment" do
    png = Base64.decode64(
      "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg=="
    )
    recipe.image.attach(
      io: StringIO.new(png),
      filename: "one.png",
      content_type: "image/png"
    )

    entry = MenuEntry.create!(
      menu: menu,
      recipe: recipe,
      weekday: 0,
      meal_type: "desayuno",
      freeform_text: nil
    )

    result = described_class.call(entry: entry, meal_type: "desayuno")
    expect(result.display).to eq(:uploaded)
    expect(result.uploaded_image).to be_present
    expect(result.uploaded_image).to eq(recipe.image)
  end
end
