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

    doc = Nokogiri::HTML(response.body)
    slot = doc.at_css(%([data-test="menu-entry-slot"][data-weekday="0"][data-meal-type="desayuno"]))
    expect(slot).to be_present

    group_keys = slot.css(%([data-test="dish-picker-group"])).map { |node| node["data-meal-type"] }
    expect(group_keys).to eq(%w[desayuno almuerzo cena])

    expect(response.body).to include(I18n.t("menus.slots.dish_blank"))
  end
end
