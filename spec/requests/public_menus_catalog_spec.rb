# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Public menus catalog", type: :request do
  let(:viewer) { create(:user, password: "Password123!", timezone: "Etc/UTC") }
  let(:author) { create(:user, password: "Password123!", timezone: "Etc/UTC") }

  before do
    post sign_in_path, params: { email: viewer.email, password: "Password123!" }
  end

  def create_menu(user:, name:, publicly_shareable:)
    Menu.create!(user: user, name: name, publicly_shareable: publicly_shareable)
  end

  # [REQ-MENU-006]
  it "lists only menus that are publicly shareable" do
    create_menu(user: author, name: "Público", publicly_shareable: true)
    create_menu(user: author, name: "Privado", publicly_shareable: false)

    get public_menus_path

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Público")
    expect(response.body).not_to include("Privado")
  end

  # [REQ-MENU-006]
  it "shows a publicly shareable menu by id" do
    menu = create_menu(user: author, name: "Semana fit", publicly_shareable: true)

    get public_menu_path(menu)

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Semana fit")
  end

  # [REQ-MENU-006]
  it "returns not found for a menu that is not publicly shareable" do
    menu = create_menu(user: author, name: "Secret", publicly_shareable: false)

    get public_menu_path(menu)

    expect(response).to have_http_status(:not_found)
  end

  # [REQ-MENU-006]
  it "returns not found after public sharing is revoked" do
    menu = create_menu(user: author, name: "Was public", publicly_shareable: true)
    menu.update!(publicly_shareable: false)

    get public_menu_path(menu)

    expect(response).to have_http_status(:not_found)
  end

  # [REQ-MENU-006]
  it "does not expose author email in index or show HTML" do
    menu = create_menu(user: author, name: "Shared menu", publicly_shareable: true)
    expect(author.email).to be_present

    get public_menus_path
    expect(response.body).not_to include(author.email)

    get public_menu_path(menu)
    expect(response.body).not_to include(author.email)
  end
end
