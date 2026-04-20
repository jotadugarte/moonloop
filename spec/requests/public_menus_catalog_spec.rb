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

  # [REQ-CAT-001]
  it "orders the catalog index by name by default, for sort=name, and for unknown sort values" do
    create_menu(user: author, name: "Aaa", publicly_shareable: true)
    z = create_menu(user: author, name: "Zzz", publicly_shareable: true)
    z.update_columns(public_catalog_adoptions_count: 50, public_catalog_distinct_adopters_count: 5)

    get public_menus_path
    expect(response.body.index("Aaa")).to be < response.body.index("Zzz")

    get public_menus_path(sort: "name")
    expect(response.body.index("Aaa")).to be < response.body.index("Zzz")

    get public_menus_path(sort: "  NAME ")
    expect(response.body.index("Aaa")).to be < response.body.index("Zzz")

    get public_menus_path(sort: "not-a-real-sort")
    expect(response.body.index("Aaa")).to be < response.body.index("Zzz")
  end

  # [REQ-CAT-001]
  it "shows catalog adoption metrics on each index row (Spanish default)" do
    m = create_menu(user: author, name: "Con stats", publicly_shareable: true)
    m.update_columns(public_catalog_adoptions_count: 3, public_catalog_distinct_adopters_count: 2)

    get public_menus_path

    expect(response.body).to include(I18n.t("public_catalog.metrics.total_adoptions", count: 3, locale: :es))
    expect(response.body).to include(I18n.t("public_catalog.metrics.distinct_adopters", count: 2, locale: :es))
    expect(response.body).to include("role=\"group\"")
    expect(response.body).to include("catalog-index-metrics")
  end

  # [REQ-CAT-001]
  it "shows catalog adoption metrics in English when I18n.locale is :en" do
    m = create_menu(user: author, name: "Stats", publicly_shareable: true)
    m.update_columns(public_catalog_adoptions_count: 1, public_catalog_distinct_adopters_count: 1)
    prev = I18n.locale
    I18n.locale = :en
    get public_menus_path
    expect(response.body).to include(I18n.t("public_catalog.metrics.total_adoptions", count: 1, locale: :en))
    expect(response.body).to include(I18n.t("public_catalog.metrics.distinct_adopters", count: 1, locale: :en))
  ensure
    I18n.locale = prev
  end

  # [REQ-CAT-001]
  it "orders the catalog index by popularity when sort=popular" do
    create_menu(user: author, name: "Aaa", publicly_shareable: true)
    z = create_menu(user: author, name: "Zzz", publicly_shareable: true)
    z.update_columns(public_catalog_adoptions_count: 50, public_catalog_distinct_adopters_count: 5)

    get public_menus_path(sort: "popular")

    expect(response.body.index("Zzz")).to be < response.body.index("Aaa")
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
