require "rails_helper"

RSpec.describe "Phase 4 — menus & recipes models", type: :model do
  def connection
    ActiveRecord::Base.connection
  end

  # [REQ-MENU-001, REQ-MENU-002]
  it "creates core tables for menus, recipes, and menu entries" do
    expect(connection.data_source_exists?("menus")).to eq(true)
    expect(connection.data_source_exists?("recipes")).to eq(true)
    expect(connection.data_source_exists?("menu_entries")).to eq(true)
    expect(connection.data_source_exists?("phase_assignments")).to eq(true)
  end

  # [REQ-MENU-002]
  it "installs ActiveStorage tables required for recipe image upload" do
    expect(connection.data_source_exists?("active_storage_blobs")).to eq(true)
    expect(connection.data_source_exists?("active_storage_attachments")).to eq(true)
  end

  # [REQ-MENU-001, REQ-MENU-002]
  it "defines AR models Menu, Recipe, MenuEntry, and PhaseAssignment" do
    expect("Menu".safe_constantize).to be_present
    expect("Recipe".safe_constantize).to be_present
    expect("MenuEntry".safe_constantize).to be_present
    expect("PhaseAssignment".safe_constantize).to be_present
  end

  # [REQ-MENU-001]
  it "Menu belongs to user" do
    menu_class = "Menu".safe_constantize
    expect(menu_class).to be_present
    expect(menu_class.reflect_on_association(:user).macro).to eq(:belongs_to)
  end

  # [REQ-MENU-001]
  it "Menu has many menu_entries" do
    menu_class = "Menu".safe_constantize
    expect(menu_class).to be_present
    expect(menu_class.reflect_on_association(:menu_entries).macro).to eq(:has_many)
  end

  # [REQ-MENU-002]
  it "Recipe belongs to user" do
    recipe_class = "Recipe".safe_constantize
    expect(recipe_class).to be_present
    expect(recipe_class.reflect_on_association(:user).macro).to eq(:belongs_to)
  end

  # [REQ-MENU-002]
  it "Recipe supports image attachment" do
    recipe_class = "Recipe".safe_constantize
    expect(recipe_class).to be_present
    reflection = recipe_class.reflect_on_attachment(:image)
    expect(reflection).to be_present
    expect(reflection.macro).to eq(:has_one_attached)
  end

  # [REQ-MENU-001]
  it "MenuEntry belongs to menu and optionally belongs to recipe" do
    entry_class = "MenuEntry".safe_constantize
    expect(entry_class).to be_present
    expect(entry_class.reflect_on_association(:menu).macro).to eq(:belongs_to)
    expect(entry_class.reflect_on_association(:recipe).macro).to eq(:belongs_to)
    expect(entry_class.reflect_on_association(:recipe).options[:optional]).to eq(true)
  end

  # [REQ-MENU-001]
  it "enforces uniqueness of menu_entries for (menu, weekday, meal_type)" do
    user = create(:user)
    menu = Menu.create!(user: user, name: "Semana A")
    recipe = Recipe.create!(user: user, name: "Avena")

    MenuEntry.create!(
      menu: menu,
      recipe: recipe,
      weekday: 1,
      meal_type: "desayuno",
      freeform_text: nil
    )

    dup = MenuEntry.new(
      menu: menu,
      recipe: recipe,
      weekday: 1,
      meal_type: "desayuno",
      freeform_text: nil
    )

    expect(dup).not_to be_valid
  end

  # [REQ-MENU-001, REQ-MENU-002]
  it "requires menu entry content: recipe and/or freeform_text" do
    user = create(:user)
    menu = Menu.create!(user: user, name: "Semana B")

    blank = MenuEntry.new(menu: menu, recipe: nil, weekday: 2, meal_type: "cena", freeform_text: "   ")
    expect(blank).not_to be_valid

    with_text = MenuEntry.new(menu: menu, recipe: nil, weekday: 2, meal_type: "cena", freeform_text: "Ensalada")
    expect(with_text).to be_valid
  end

  # [REQ-MENU-002]
  it "requires recipe name" do
    user = create(:user)
    recipe = Recipe.new(user: user, name: "   ")
    expect(recipe).not_to be_valid
  end
end
