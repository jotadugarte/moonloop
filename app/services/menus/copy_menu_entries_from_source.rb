# frozen_string_literal: true

module Menus
  class CopyMenuEntriesFromSource
    def self.call(target_menu:, source_menu:, recipe_map:)
      source_menu.menu_entries.order(:weekday, :meal_type).each do |entry|
        new_recipe_id =
          if entry.recipe_id.present?
            recipe_map.fetch(entry.recipe_id)
          end

        target_menu.menu_entries.build(
          weekday: entry.weekday,
          meal_type: entry.meal_type,
          recipe_id: new_recipe_id,
          freeform_text: entry.freeform_text
        )
      end
    end
  end
end
