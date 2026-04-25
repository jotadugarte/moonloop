# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Menu entries (Turbo)", type: :request do
  let(:user) { create(:user, password: "Password123!", timezone: "Etc/UTC") }

  before do
    post sign_in_path, params: { email: user.email, password: "Password123!" }
  end

  # [REQ-MENU-001]
  it "creates/updates a slot via turbo-stream" do
    menu = Menu.create!(user: user, name: "Semana")
    recipe = Recipe.create!(user: user, name: "Avena")

    post menu_menu_entries_path(menu),
      params: {
        menu_entry: {
          weekday: 1,
          meal_type: "desayuno",
          recipe_id: recipe.id,
          freeform_text: ""
        }
      },
      as: :turbo_stream

    expect(response).to have_http_status(:ok)
    expect(response.media_type).to eq(Mime[:turbo_stream])

    entry = menu.menu_entries.find_by!(weekday: 1, meal_type: "desayuno")
    expect(entry.recipe_id).to eq(recipe.id)
  end

  # [REQ-MENU-001]
  it "clears a slot via turbo-stream" do
    menu = Menu.create!(user: user, name: "Semana")
    recipe = Recipe.create!(user: user, name: "Avena")
    MenuEntry.create!(
      menu: menu,
      recipe: recipe,
      weekday: 2,
      meal_type: "cena",
      freeform_text: nil
    )

    delete clear_menu_menu_entries_path(menu),
      params: { weekday: 2, meal_type: "cena" },
      as: :turbo_stream

    expect(response).to have_http_status(:ok)
    expect(response.media_type).to eq(Mime[:turbo_stream])
    expect(menu.menu_entries.find_by(weekday: 2, meal_type: "cena")).to be_nil
  end

  # [REQ-MENU-001]
  it "deletes the entry row when both recipe and freeform are blank (sparse slots)" do
    allow_freeform_user = create(:user, password: "Password123!", timezone: "Etc/UTC", allow_menu_freeform: true)
    post sign_in_path, params: { email: allow_freeform_user.email, password: "Password123!" }

    menu = Menu.create!(user: allow_freeform_user, name: "Semana")
    recipe = Recipe.create!(user: allow_freeform_user, name: "Tostadas")
    Menus::UpsertEntry.call(
      user: allow_freeform_user,
      menu: menu,
      weekday: 2,
      meal_type: "desayuno",
      recipe_id: recipe.id,
      freeform_text: "sin azúcar"
    )

    expect(menu.menu_entries.find_by(weekday: 2, meal_type: "desayuno")).to be_present

    post menu_menu_entries_path(menu),
      params: {
        menu_entry: {
          weekday: 2,
          meal_type: "desayuno",
          recipe_id: "",
          freeform_text: ""
        }
      },
      as: :turbo_stream

    expect(response).to have_http_status(:ok)
    expect(response.media_type).to eq(Mime[:turbo_stream])
    expect(menu.menu_entries.find_by(weekday: 2, meal_type: "desayuno")).to be_nil
  end
end
