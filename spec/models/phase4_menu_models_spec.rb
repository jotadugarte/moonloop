require "rails_helper"

RSpec.describe "Phase 4 — menus & dishes models", type: :model do
  def connection
    ActiveRecord::Base.connection
  end

  # [REQ-MENU-001, REQ-MENU-002]
  it "creates core tables for menus, dishes, and menu entries" do
    expect(connection.data_source_exists?("menus")).to eq(true)
    expect(connection.data_source_exists?("dishes")).to eq(true)
    expect(connection.data_source_exists?("menu_entries")).to eq(true)
    expect(connection.data_source_exists?("phase_assignments")).to eq(true)
  end

  # [REQ-MENU-002]
  it "installs ActiveStorage tables required for dish image upload" do
    expect(connection.data_source_exists?("active_storage_blobs")).to eq(true)
    expect(connection.data_source_exists?("active_storage_attachments")).to eq(true)
  end

  # [REQ-MENU-001, REQ-MENU-002]
  it "defines AR models Menu, Dish, MenuEntry, and PhaseAssignment" do
    expect("Menu".safe_constantize).to be_present
    expect("Dish".safe_constantize).to be_present
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
  it "Dish belongs to user" do
    dish_class = "Dish".safe_constantize
    expect(dish_class).to be_present
    expect(dish_class.reflect_on_association(:user).macro).to eq(:belongs_to)
  end

  # [REQ-MENU-002]
  it "Dish supports image attachment" do
    dish_class = "Dish".safe_constantize
    expect(dish_class).to be_present
    reflection = dish_class.reflect_on_attachment(:image)
    expect(reflection).to be_present
    expect(reflection.macro).to eq(:has_one_attached)
  end

  # [REQ-MENU-001]
  it "MenuEntry belongs to menu and optionally belongs to dish" do
    entry_class = "MenuEntry".safe_constantize
    expect(entry_class).to be_present
    expect(entry_class.reflect_on_association(:menu).macro).to eq(:belongs_to)
    expect(entry_class.reflect_on_association(:dish).macro).to eq(:belongs_to)
    expect(entry_class.reflect_on_association(:dish).options[:optional]).to eq(true)
  end

  # [REQ-MENU-001]
  it "enforces uniqueness of menu_entries for (menu, weekday, meal_type)" do
    user = create(:user)
    menu = Menu.create!(user: user, name: "Semana A")
    dish = Dish.create!(user: user, name: "Avena")

    MenuEntry.create!(
      menu: menu,
      dish: dish,
      weekday: 1,
      meal_type: "desayuno",
      freeform_text: nil
    )

    dup = MenuEntry.new(
      menu: menu,
      dish: dish,
      weekday: 1,
      meal_type: "desayuno",
      freeform_text: nil
    )

    expect(dup).not_to be_valid
  end

  # [REQ-MENU-001, REQ-MENU-002]
  it "requires menu entry content: dish and/or freeform_text" do
    user = create(:user)
    menu = Menu.create!(user: user, name: "Semana B")

    blank = MenuEntry.new(menu: menu, dish: nil, weekday: 2, meal_type: "cena", freeform_text: "   ")
    expect(blank).not_to be_valid

    with_text = MenuEntry.new(menu: menu, dish: nil, weekday: 2, meal_type: "cena", freeform_text: "Ensalada")
    expect(with_text).to be_valid
  end

  # [REQ-MENU-002]
  it "requires dish name" do
    user = create(:user)
    dish = Dish.new(user: user, name: "   ")
    expect(dish).not_to be_valid
  end
end
