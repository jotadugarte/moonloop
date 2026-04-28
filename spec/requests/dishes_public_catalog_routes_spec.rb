# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Dishes public catalog and legacy routes", type: :request do
  let(:author) { create(:user, password: "Password123!", timezone: "Etc/UTC") }
  let(:viewer) { create(:user, password: "Password123!", timezone: "Etc/UTC") }

  describe "legacy redirects to canonical dish URLs" do
    # [REQ-MENU-002, REQ-MENU-006]
    it "redirects GET /recipes to the dishes index with 301" do
      get "/recipes"

      expect(response).to have_http_status(:moved_permanently)
      expect(response).to redirect_to("/platos")
    end

    # [REQ-MENU-002, REQ-MENU-006]
    it "redirects GET /recetas to the dishes index with 301" do
      get "/recetas"

      expect(response).to have_http_status(:moved_permanently)
      expect(response).to redirect_to("/platos")
    end

    # [REQ-MENU-002, REQ-MENU-006]
    it "redirects GET /public_recipes to the public dishes index with 301" do
      get "/public_recipes"

      expect(response).to have_http_status(:moved_permanently)
      expect(response).to redirect_to("/public_dishes")
    end

    # [REQ-MENU-002, REQ-MENU-006]
    it "redirects GET /recipes/:id to the canonical dish path with 301" do
      dish = create(:dish, user: author)

      get "/recipes/#{dish.id}"

      expect(response).to have_http_status(:moved_permanently)
      expect(response).to redirect_to("/platos/#{dish.id}")
    end
  end

  describe "public_dishes#show when the item has no instructions" do
    let(:public_dish) do
      create(
        :dish,
        user: author,
        name: "Plain",
        instructions: nil,
        publicly_shareable: true
      )
    end

    # [REQ-MENU-002, REQ-MENU-006]
    it "shows neutral preparation copy for a non-owner and does not show the owner CTA" do
      post sign_in_path, params: { email: viewer.email, password: "Password123!" }
      get "/public_dishes/#{public_dish.id}", params: { locale: :en }

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(I18n.t("public_dishes.show.preparation_neutral", locale: :en))
      expect(response.body).not_to include(I18n.t("public_dishes.show.add_preparation_cta", locale: :en))
    end

    # [REQ-MENU-002, REQ-MENU-006]
    it "shows neutral copy and the add-preparation CTA for the owner" do
      post sign_in_path, params: { email: author.email, password: "Password123!" }
      get "/public_dishes/#{public_dish.id}", params: { locale: :en }

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(I18n.t("public_dishes.show.preparation_neutral", locale: :en))
      expect(response.body).to include(I18n.t("public_dishes.show.add_preparation_cta", locale: :en))
    end
  end
end
