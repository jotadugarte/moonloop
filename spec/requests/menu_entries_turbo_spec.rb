# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Menu entries (Turbo)", type: :request do
  let(:user) { create(:user, password: "Password123!", timezone: "Etc/UTC") }

  before do
    post sign_in_path, params: { email: user.email, password: "Password123!" }
  end

  # [REQ-MENU-001]
  it "creates/updates a slot via turbo-stream" do
    menu = create(:menu, user: user, name: "Semana")
    dish = create(:dish, user: user, name: "Avena")

    post menu_menu_entries_path(menu),
      params: {
        menu_entry: {
          weekday: 1,
          meal_type: "desayuno",
          dish_id: dish.id,
          freeform_text: ""
        }
      },
      as: :turbo_stream

    expect(response).to have_http_status(:ok)
    expect(response.media_type).to eq(Mime[:turbo_stream])

    entry = menu.menu_entries.find_by!(weekday: 1, meal_type: "desayuno")
    expect(entry.dish_id).to eq(dish.id)
  end

  # [REQ-MENU-001]
  it "clears a slot via turbo-stream" do
    menu = create(:menu, user: user, name: "Semana")
    dish = create(:dish, user: user, name: "Avena")
    create(:menu_entry, menu: menu, dish: dish, weekday: 2, meal_type: "cena", freeform_text: nil)

    delete clear_menu_menu_entries_path(menu),
      params: { weekday: 2, meal_type: "cena" },
      as: :turbo_stream

    expect(response).to have_http_status(:ok)
    expect(response.media_type).to eq(Mime[:turbo_stream])
    expect(menu.menu_entries.find_by(weekday: 2, meal_type: "cena")).to be_nil
  end

  # [REQ-MENU-001]
  it "deletes the entry row when both dish and freeform are blank (sparse slots)" do
    allow_freeform_user = create(:user, password: "Password123!", timezone: "Etc/UTC", allow_menu_freeform: true)
    post sign_in_path, params: { email: allow_freeform_user.email, password: "Password123!" }

    menu = create(:menu, user: allow_freeform_user, name: "Semana")
    dish = create(:dish, user: allow_freeform_user, name: "Tostadas")
    Menus::UpsertEntry.call(
      user: allow_freeform_user,
      menu: menu,
      weekday: 2,
      meal_type: "desayuno",
      dish_id: dish.id,
      freeform_text: "sin azúcar"
    )

    expect(menu.menu_entries.find_by(weekday: 2, meal_type: "desayuno")).to be_present

    post menu_menu_entries_path(menu),
      params: {
        menu_entry: {
          weekday: 2,
          meal_type: "desayuno",
          dish_id: "",
          freeform_text: ""
        }
      },
      as: :turbo_stream

    expect(response).to have_http_status(:ok)
    expect(response.media_type).to eq(Mime[:turbo_stream])
    expect(menu.menu_entries.find_by(weekday: 2, meal_type: "desayuno")).to be_nil
  end
end
