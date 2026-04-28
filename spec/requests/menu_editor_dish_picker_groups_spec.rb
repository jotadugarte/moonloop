# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Menu editor dish picker groups", type: :request do
  let(:user) { create(:user, password: "Password123!", timezone: "Etc/UTC") }

  before do
    post sign_in_path, params: { email: user.email, password: "Password123!" }
  end

  # [REQ-MENU-001]
  it "renders dish picker groups in order and includes the blank option label" do
    menu = create(:menu, user: user, name: "Semana")
    create(:dish, user: user, name: "Avena", meal_type: "desayuno")
    create(:dish, user: user, name: "Ensalada", meal_type: "almuerzo")
    create(:dish, user: user, name: "Sopa", meal_type: "cena")

    get edit_menu_path(menu)

    expect(response).to have_http_status(:ok)

    slot_marker = %(data-test="menu-entry-slot" data-weekday="0" data-meal-type="desayuno")
    expect(response.body).to include(slot_marker)

    group_desayuno = %(data-test="dish-picker-group" data-meal-type="desayuno")
    group_almuerzo = %(data-test="dish-picker-group" data-meal-type="almuerzo")
    group_cena = %(data-test="dish-picker-group" data-meal-type="cena")

    slot_start = response.body.index(slot_marker)
    expect(slot_start).to be_present

    within_slot = response.body[slot_start, 12_000]
    expect(within_slot.index(group_desayuno)).to be < within_slot.index(group_almuerzo)
    expect(within_slot.index(group_almuerzo)).to be < within_slot.index(group_cena)

    expect(response.body).to include(I18n.t("menus.slots.dish_blank"))
  end
end

