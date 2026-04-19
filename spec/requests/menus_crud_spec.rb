# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Menus CRUD", type: :request do
  let(:user) { create(:user, password: "Password123!", timezone: "Etc/UTC") }

  before do
    post sign_in_path, params: { email: user.email, password: "Password123!" }
  end

  # [REQ-MENU-001]
  it "lists menus for the signed-in user" do
    Menu.create!(user: user, name: "Semana A")

    get "/menus"

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Semana A")
  end

  # [REQ-MENU-001]
  it "creates a menu" do
    post "/menus", params: { menu: { name: "Nueva semana" } }

    expect(response).to have_http_status(:found)
    expect(Menu.find_by(user: user, name: "Nueva semana")).to be_present
  end

  # [REQ-MENU-001, REQ-MENU-006]
  it "creates a menu with publicly_shareable when the checkbox is on" do
    post "/menus", params: { menu: { name: "Catálogo", publicly_shareable: "1" } }

    expect(response).to have_http_status(:found)
    m = Menu.find_by!(user: user, name: "Catálogo")
    expect(m.publicly_shareable).to be(true)
  end

  # [REQ-MENU-001, REQ-MENU-006]
  it "updates menu name and publicly_shareable from edit" do
    m = Menu.create!(user: user, name: "Semana", publicly_shareable: false)

    patch menu_path(m), params: { menu: { name: "Semana 2", publicly_shareable: "1" } }

    expect(response).to redirect_to(edit_menu_path(m))
    m.reload
    expect(m.name).to eq("Semana 2")
    expect(m.publicly_shareable).to be(true)
  end

  # [REQ-MENU-001]
  it "forbids updating another user's menu" do
    other = create(:user, password: "Password123!", timezone: "Etc/UTC")
    foreign = Menu.create!(user: other, name: "Ajeno", publicly_shareable: false)

    patch menu_path(foreign), params: { menu: { name: "Hack", publicly_shareable: "1" } }

    expect(response).to have_http_status(:not_found)
    expect(foreign.reload.name).to eq("Ajeno")
  end

  # [REQ-MENU-001]
  it "rejects a duplicate menu name for the same user (normalized)" do
    Menu.create!(user: user, name: "Plan")

    post "/menus", params: { menu: { name: "  PLAN " } }

    expect(response).to have_http_status(:unprocessable_content)
    expect(Menu.where(user: user, name_normalized: "plan").count).to eq(1)
  end

  # [REQ-MENU-001]
  it "forbids accessing another user's menu editor" do
    other = create(:user, password: "Password123!", timezone: "Etc/UTC")
    foreign = Menu.create!(user: other, name: "Ajeno")

    get "/menus/#{foreign.id}/edit"

    expect(response).to have_http_status(:not_found)
  end
end
