# frozen_string_literal: true

module Menus
  class CopyMenuEntriesFromSource
    def self.call(target_menu:, source_menu:, dish_map:)
      source_menu.menu_entries.order(:weekday, :meal_type).each do |entry|
        new_dish_id =
          if entry.dish_id.present?
            dish_map.fetch(entry.dish_id)
          end

        target_menu.menu_entries.build(
          weekday: entry.weekday,
          meal_type: entry.meal_type,
          dish_id: new_dish_id,
          freeform_text: entry.freeform_text
        )
      end
    end
  end
end
