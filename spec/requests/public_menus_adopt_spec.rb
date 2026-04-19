# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Public menus adopt", type: :request do
  let(:adopter) { create(:user, password: "Password123!", timezone: "Etc/UTC") }
  let(:author) { create(:user, password: "Password123!", timezone: "Etc/UTC") }

  def create_public_menu(user:, name:, publicly_shareable: true)
    Menu.create!(user: user, name: name, publicly_shareable: publicly_shareable)
  end

  # [REQ-MENU-006]
  context "when signed in as adopter" do
    before do
      post sign_in_path, params: { email: adopter.email, password: "Password123!" }
    end

    it "creates an adopted copy with chosen name, entries, and source link" do
      origin = create_public_menu(user: author, name: "Plan autor")
      MenuEntry.create!(menu: origin, weekday: 2, meal_type: "cena", freeform_text: "Ensalada")

      expect do
        post adopt_public_menu_path(origin), params: { name: "Mi copia menú" }
      end.to change { Menu.count }.by(1)

      expect(response).to have_http_status(:found)
      copy = Menu.find_by!(user: adopter, name: "Mi copia menú")
      expect(copy.source_menu_id).to eq(origin.id)
      expect(copy.menu_entries.count).to eq(1)
      entry = copy.menu_entries.sole
      expect(entry.weekday).to eq(2)
      expect(entry.meal_type).to eq("cena")
      expect(entry.freeform_text).to include("Ensalada")
      expect(response.headers["Location"]).to include(edit_menu_path(copy))
    end

    it "duplicates referenced recipes onto the adopter for recipe slots" do
      origin = create_public_menu(user: author, name: "Con receta")
      recipe = Recipe.create!(user: author, name: "Pollo", instructions: "Hornear")
      MenuEntry.create!(menu: origin, weekday: 1, meal_type: "desayuno", recipe: recipe)

      expect do
        post adopt_public_menu_path(origin), params: { name: "Copia con recetas" }
      end.to change { Menu.count }.by(1).and change { Recipe.where(user: adopter).count }.by(1)

      copy = Menu.find_by!(user: adopter, name: "Copia con recetas")
      adopted_recipe = Recipe.find(copy.menu_entries.sole.recipe_id)
      expect(adopted_recipe.user_id).to eq(adopter.id)
      expect(adopted_recipe.name).to eq("Pollo")
      expect(adopted_recipe.instructions).to include("Hornear")
    end

    it "rejects a second adoption of the same origin" do
      origin = create_public_menu(user: author, name: "Once")
      MenuEntry.create!(menu: origin, weekday: 0, meal_type: "merienda", freeform_text: "x")
      post adopt_public_menu_path(origin), params: { name: "Primera" }
      expect(response).to have_http_status(:found)

      post adopt_public_menu_path(origin), params: { name: "Segunda" }

      expect(response).to have_http_status(:found)
      expect(flash[:alert]).to eq(I18n.t("public_menus.adopt.errors.already_adopted"))
    end

    it "rejects adoption when the chosen name collides with an existing menu for the adopter" do
      Menu.create!(user: adopter, name: "Existing", publicly_shareable: false)
      origin = create_public_menu(user: author, name: "Origin")
      MenuEntry.create!(menu: origin, weekday: 3, meal_type: "almuerzo", freeform_text: "y")

      post adopt_public_menu_path(origin), params: { name: "Existing" }

      expect(response).to have_http_status(:found)
      expect(flash[:alert]).to eq(I18n.t("adoption.invalid_record.name_taken"))
    end

    it "rejects adoption of the adopter's own public menu" do
      own = create_public_menu(user: adopter, name: "Mine")
      MenuEntry.create!(menu: own, weekday: 0, meal_type: "cena", freeform_text: "z")

      post adopt_public_menu_path(own), params: { name: "Copy try" }

      expect(response).to have_http_status(:found)
      expect(flash[:alert]).to eq(I18n.t("public_menus.adopt.errors.cannot_adopt_own"))
    end
  end

  # [REQ-MENU-006]
  context "when not signed in" do
    it "redirects to sign in" do
      origin = create_public_menu(user: author, name: "Publico")
      MenuEntry.create!(menu: origin, weekday: 0, meal_type: "cena", freeform_text: "a")

      post adopt_public_menu_path(origin), params: { name: "Nope" }

      expect(response).to redirect_to(sign_in_path)
    end
  end
end
