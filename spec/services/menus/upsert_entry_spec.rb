# frozen_string_literal: true

require "rails_helper"

RSpec.describe Menus::UpsertEntry do
  let(:user) { create(:user, password: "Password123!", allow_menu_freeform: allow_freeform) }
  let(:allow_freeform) { true }
  let(:menu) { Menu.create!(user: user, name: "Semana") }
  let(:recipe) { Recipe.create!(user: user, name: "Avena") }

  describe ".call" do
    # [REQ-MENU-001]
    it "persists recipe and freeform when allowed" do
      described_class.call(
        user: user,
        menu: menu,
        weekday: 1,
        meal_type: "desayuno",
        recipe_id: recipe.id,
        freeform_text: "extra"
      )

      entry = menu.menu_entries.find_by!(weekday: 1, meal_type: "desayuno")
      expect(entry.recipe_id).to eq(recipe.id)
      expect(entry.freeform_text).to eq("extra")
    end

    context "when freeform is disabled for the user" do
      let(:allow_freeform) { false }

      # [REQ-MENU-001]
      it "ignores freeform params and saves recipe only" do
        described_class.call(
          user: user,
          menu: menu,
          weekday: 3,
          meal_type: "almuerzo",
          recipe_id: recipe.id,
          freeform_text: "should not persist"
        )

        entry = menu.menu_entries.find_by!(weekday: 3, meal_type: "almuerzo")
        expect(entry.recipe_id).to eq(recipe.id)
        expect(entry.freeform_text).to be_blank
      end

      # [REQ-MENU-001]
      it "does not clear a freeform-only legacy slot on empty submit" do
        MenuEntry.create!(
          menu: menu,
          recipe: nil,
          weekday: 4,
          meal_type: "cena",
          freeform_text: "legacy note"
        )

        expect do
          described_class.call(
            user: user,
            menu: menu,
            weekday: 4,
            meal_type: "cena",
            recipe_id: "",
            freeform_text: ""
          )
        end.to raise_error(ActiveRecord::RecordInvalid)

        entry = menu.menu_entries.find_by!(weekday: 4, meal_type: "cena")
        expect(entry.freeform_text).to eq("legacy note")
      end

      # [REQ-MENU-001]
      it "replaces legacy freeform-only slot when a recipe is chosen" do
        MenuEntry.create!(
          menu: menu,
          recipe: nil,
          weekday: 5,
          meal_type: "merienda",
          freeform_text: "legacy note"
        )

        described_class.call(
          user: user,
          menu: menu,
          weekday: 5,
          meal_type: "merienda",
          recipe_id: recipe.id,
          freeform_text: ""
        )

        entry = menu.menu_entries.find_by!(weekday: 5, meal_type: "merienda")
        expect(entry.recipe_id).to eq(recipe.id)
        expect(entry.freeform_text).to be_blank
      end
    end
  end
end
