# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Public phases catalog", type: :request do
  let(:viewer) { create(:user, password: "Password123!", timezone: "Etc/UTC") }
  let(:author) { create(:user, password: "Password123!", timezone: "Etc/UTC") }

  # [REQ-CAT-001] — phases public catalog (REQ-ID finalized in SPEC step S11 of task plan)
  it "requires authentication" do
    get public_phases_path

    expect(response).to redirect_to(sign_in_path)
  end

  before do
    post sign_in_path, params: { email: viewer.email, password: "Password123!" }
  end

  # [REQ-CAT-001] — phases public catalog (REQ-ID finalized in SPEC step S11 of task plan)
  it "lists only phases that are publicly shareable" do
    Phase.create!(user: author, name: "Pública", weeks_total: 4, publicly_shareable: true)
    Phase.create!(user: author, name: "Privada", weeks_total: 4, publicly_shareable: false)

    get public_phases_path

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Pública")
    expect(response.body).not_to include("Privada")
  end

  # [REQ-CAT-001] — phases public catalog (REQ-ID finalized in SPEC step S11 of task plan)
  it "shows a public phase by id" do
    phase = Phase.create!(user: author, name: "Fase catálogo", weeks_total: 4, publicly_shareable: true)

    get public_phase_path(phase)

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Fase catálogo")
  end

  # [REQ-CAT-001] — phases public catalog (REQ-ID finalized in SPEC step S11 of task plan)
  it "returns not found for a phase that is not publicly shareable" do
    phase = Phase.create!(user: author, name: "Secret", weeks_total: 4, publicly_shareable: false)

    get public_phase_path(phase)

    expect(response).to have_http_status(:not_found)
  end

  # [REQ-CAT-001]
  it "orders the catalog index by name by default and by popularity when sort=popular" do
    Phase.create!(user: author, name: "Aaa", weeks_total: 4, publicly_shareable: true)
    z = Phase.create!(user: author, name: "Zzz", weeks_total: 4, publicly_shareable: true)
    z.update_columns(public_catalog_adoptions_count: 30, public_catalog_distinct_adopters_count: 3)

    get public_phases_path
    expect(response.body.index("Aaa")).to be < response.body.index("Zzz")

    get public_phases_path(sort: "popular")
    expect(response.body.index("Zzz")).to be < response.body.index("Aaa")
  end

  # [REQ-CAT-001]
  it "shows catalog adoption metrics on each phase index row" do
    p = Phase.create!(user: author, name: "Fase stats", weeks_total: 4, publicly_shareable: true)
    p.update_columns(public_catalog_adoptions_count: 5, public_catalog_distinct_adopters_count: 3)

    get public_phases_path

    expect(response.body).to include(I18n.t("public_catalog.metrics.total_adoptions", count: 5, locale: :es))
    expect(response.body).to include(I18n.t("public_catalog.metrics.distinct_adopters", count: 3, locale: :es))
    expect(response.body).to include("catalog-index-metrics")
  end

  # [REQ-CAT-001]
  it "applies discovery filters on the public index" do
    keep = Phase.create!(user: author, name: "Phase keep", weeks_total: 4, publicly_shareable: true)
    Catalog::ListingFacet.create!(listable: keep, difficulty_level: "advanced")
    drop = Phase.create!(user: author, name: "Phase drop", weeks_total: 4, publicly_shareable: true)
    Catalog::ListingFacet.create!(listable: drop, difficulty_level: "beginner")

    get public_phases_path(difficulty: "advanced")

    expect(response.body).to include("Phase keep")
    expect(response.body).not_to include("Phase drop")
  end

  # [REQ-CAT-001]
  it "does not expose author email in index or show HTML" do
    phase = Phase.create!(user: author, name: "Shared phase", weeks_total: 4, publicly_shareable: true)
    expect(author.email).to be_present

    get public_phases_path
    expect(response.body).not_to include(author.email)

    get public_phase_path(phase)
    expect(response.body).not_to include(author.email)
  end
end

