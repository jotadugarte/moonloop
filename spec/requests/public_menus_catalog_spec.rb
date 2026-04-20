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

  # [REQ-CAT-001]
  it "filters the index by partial goal phrase (q), case-insensitive" do
    m_hit = create_menu(user: author, name: "Menu hit", publicly_shareable: true)
    Catalog::ListingFacet.create!(listable: m_hit, goal_phrase: "Ganancia muscular")
    m_miss = create_menu(user: author, name: "Menu miss", publicly_shareable: true)
    Catalog::ListingFacet.create!(listable: m_miss, goal_phrase: "Pérdida de peso")

    get public_menus_path(q: "MUSCULAR")

    expect(response.body).to include("Menu hit")
    expect(response.body).not_to include("Menu miss")
  end

  # [REQ-CAT-001]
  it "filters by difficulty and combines with q using AND semantics" do
    m_ok = create_menu(user: author, name: "Ok menu", publicly_shareable: true)
    Catalog::ListingFacet.create!(
      listable: m_ok,
      goal_phrase: "Hipertrofia",
      difficulty_level: "intermediate"
    )
    m_wrong_level = create_menu(user: author, name: "Wrong level", publicly_shareable: true)
    Catalog::ListingFacet.create!(
      listable: m_wrong_level,
      goal_phrase: "Hipertrofia",
      difficulty_level: "beginner"
    )
    m_wrong_goal = create_menu(user: author, name: "Wrong goal", publicly_shareable: true)
    Catalog::ListingFacet.create!(
      listable: m_wrong_goal,
      goal_phrase: "Cardio",
      difficulty_level: "intermediate"
    )

    get public_menus_path(q: "hipertrofia", difficulty: "intermediate")

    expect(response.body).to include("Ok menu")
    expect(response.body).not_to include("Wrong level")
    expect(response.body).not_to include("Wrong goal")
  end

  # [REQ-CAT-001]
  it "filters by tags with AND semantics (all tags must appear)" do
    m_both = create_menu(user: author, name: "Both tags", publicly_shareable: true)
    Catalog::ListingFacet.create!(listable: m_both, normalized_tags: "strength,hypertrophy")
    m_one = create_menu(user: author, name: "One tag", publicly_shareable: true)
    Catalog::ListingFacet.create!(listable: m_one, normalized_tags: "strength,endurance")

    get public_menus_path(tags: "strength, hypertrophy")

    expect(response.body).to include("Both tags")
    expect(response.body).not_to include("One tag")
  end

  # [REQ-CAT-001]
  it "filters by min_weeks against facet duration span" do
    m_short = create_menu(user: author, name: "Short menu", publicly_shareable: true)
    Catalog::ListingFacet.create!(listable: m_short, duration_weeks_min: 2, duration_weeks_max: 4)
    m_long = create_menu(user: author, name: "Long menu", publicly_shareable: true)
    Catalog::ListingFacet.create!(listable: m_long, duration_weeks_min: 8, duration_weeks_max: 12)

    get public_menus_path(min_weeks: 6)

    expect(response.body).to include("Long menu")
    expect(response.body).not_to include("Short menu")
  end

  # [REQ-CAT-001]
  it "ignores invalid difficulty and non-positive week params (still lists unfiltered catalogs)" do
    plain = create_menu(user: author, name: "Plain menu", publicly_shareable: true)

    get public_menus_path(difficulty: "not-a-level", min_weeks: "0", max_weeks: "-1")

    expect(response.body).to include("Plain menu")
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
