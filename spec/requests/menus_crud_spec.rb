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

  # [REQ-MENU-001, REQ-MENU-006]
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

  # [REQ-CAT-001]
  it "lets the owner save optional catalog listing facet fields from edit" do
    m = Menu.create!(user: user, name: "Con facet", publicly_shareable: true)

    patch menu_path(m),
      params: {
        menu: {
          name: "Con facet",
          publicly_shareable: "1",
          catalog_listing_facet_attributes: {
            goal_phrase: "ganancia muscular",
            difficulty_level: "intermediate",
            normalized_tags: "bulk,strength",
            duration_weeks_min: "4",
            duration_weeks_max: "12"
          }
        }
      }

    expect(response).to redirect_to(edit_menu_path(m))
    facet = m.reload.catalog_listing_facet
    expect(facet).to be_present
    expect(facet.goal_phrase).to eq("ganancia muscular")
    expect(facet.difficulty_level).to eq("intermediate")
    expect(facet.normalized_tags).to eq("bulk,strength")
    expect(facet.duration_weeks_min).to eq(4)
    expect(facet.duration_weeks_max).to eq(12)
  end

  # [REQ-CAT-001]
  it "rejects invalid catalog listing facet tags from edit" do
    m = Menu.create!(user: user, name: "Bad tags", publicly_shareable: false)

    patch menu_path(m),
      params: {
        menu: {
          name: "Bad tags",
          publicly_shareable: "0",
          catalog_listing_facet_attributes: {
            normalized_tags: "no spaces allowed"
          }
        }
      }

    expect(response).to have_http_status(:unprocessable_content)
    expect(m.reload.catalog_listing_facet).to be_nil
  end

  # [REQ-CAT-001]
  it "removes the catalog listing facet when all discovery fields are cleared" do
    m = Menu.create!(user: user, name: "Limpio", publicly_shareable: true)
    Catalog::ListingFacet.create!(listable: m, goal_phrase: "x")

    facet = m.reload.catalog_listing_facet
    patch menu_path(m),
      params: {
        menu: {
          name: "Limpio",
          publicly_shareable: "1",
          catalog_listing_facet_attributes: {
            id: facet.id,
            goal_phrase: "",
            difficulty_level: "",
            normalized_tags: "",
            duration_weeks_min: "",
            duration_weeks_max: ""
          }
        }
      }

    expect(response).to redirect_to(edit_menu_path(m))
    expect(m.reload.catalog_listing_facet).to be_nil
  end

  # [REQ-MENU-001]
  it "forbids accessing another user's menu editor" do
    other = create(:user, password: "Password123!", timezone: "Etc/UTC")
    foreign = Menu.create!(user: other, name: "Ajeno")

    get "/menus/#{foreign.id}/edit"

    expect(response).to have_http_status(:not_found)
  end
end
