# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Public plans catalog", type: :request do
  let(:viewer) { create(:user, password: "Password123!", timezone: "Etc/UTC") }
  let(:author) { create(:user, password: "Password123!", timezone: "Etc/UTC") }

  # [REQ-CAT-001]
  it "requires authentication" do
    get public_plans_path

    expect(response).to redirect_to(sign_in_path)
  end

  context "when signed in" do
    before do
      post sign_in_path, params: { email: viewer.email, password: "Password123!" }
    end

    def routine_for(u, name)
      r = ExerciseRoutine.new(user: u, name: name)
      r.exercise_routine_lines.build(weekday: 0, position: 0, label: "Line")
      r.save!
      r
    end

    # [REQ-PHS-001]
    it "lists only plans that are publicly shareable" do
      Plan.create!(user: author, name: "Público", publicly_shareable: true)
      Plan.create!(user: author, name: "Privado", publicly_shareable: false)

      get public_plans_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Público")
      expect(response.body).not_to include("Privado")
    end

    # [REQ-PHS-001]
    it "shows a public plan and its segment lines" do
      menu = Menu.create!(user: author, name: "M")
      routine = routine_for(author, "R")
      plan = Plan.create!(user: author, name: "Plan fit", publicly_shareable: true)
      PlanAssignment.create!(
        plan: plan,
        menu: menu,
        exercise_routine: routine,
        start_week: 1,
        end_week: 4
      )

      get public_plan_path(plan)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Plan fit")
      expect(response.body).to include("M")
      expect(response.body).to include("R")
    end

    # [REQ-PHS-001]
    it "returns not found for a plan that is not publicly shareable" do
      plan = Plan.create!(user: author, name: "Secret", publicly_shareable: false)

      get public_plan_path(plan)

      expect(response).to have_http_status(:not_found)
    end

    # [REQ-CAT-001]
    it "orders the catalog index by name by default and by popularity when sort=popular" do
      Plan.create!(user: author, name: "Aaa", publicly_shareable: true)
      z = Plan.create!(user: author, name: "Zzz", publicly_shareable: true)
      z.update_columns(public_catalog_adoptions_count: 30, public_catalog_distinct_adopters_count: 3)

      get public_plans_path
      expect(response.body.index("Aaa")).to be < response.body.index("Zzz")

      get public_plans_path(sort: "popular")
      expect(response.body.index("Zzz")).to be < response.body.index("Aaa")
    end

    # [REQ-CAT-001]
    it "shows catalog adoption metrics on each plan index row" do
      p = Plan.create!(user: author, name: "Plan stats", publicly_shareable: true)
      p.update_columns(public_catalog_adoptions_count: 5, public_catalog_distinct_adopters_count: 3)

      get public_plans_path

      expect(response.body).to include(I18n.t("public_catalog.metrics.total_adoptions", count: 5, locale: :es))
      expect(response.body).to include(I18n.t("public_catalog.metrics.distinct_adopters", count: 3, locale: :es))
      expect(response.body).to include("catalog-index-metrics")
    end

    # [REQ-CAT-001]
    it "applies discovery filters on the public index" do
      p_keep = Plan.create!(user: author, name: "Plan keep", publicly_shareable: true)
      Catalog::ListingFacet.create!(listable: p_keep, difficulty_level: "advanced")
      p_drop = Plan.create!(user: author, name: "Plan drop", publicly_shareable: true)
      Catalog::ListingFacet.create!(listable: p_drop, difficulty_level: "beginner")

      get public_plans_path(difficulty: "advanced")

      expect(response.body).to include("Plan keep")
      expect(response.body).not_to include("Plan drop")
    end

    # [REQ-PHS-001]
    it "does not expose author email in index or show HTML" do
      plan = Plan.create!(user: author, name: "Shared plan", publicly_shareable: true)
      expect(author.email).to be_present

      get public_plans_path
      expect(response.body).not_to include(author.email)

      get public_plan_path(plan)
      expect(response.body).not_to include(author.email)
    end
  end
end
