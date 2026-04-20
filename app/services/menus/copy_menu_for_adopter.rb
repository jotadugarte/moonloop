# frozen_string_literal: true

module Menus
  # Deep-copies a menu (entries + duplicated recipes) onto +adopter+ without requiring the source to be public.
  class CopyMenuForAdopter
    MAX_UNIQUIFY_ITERATIONS = 10_000

    def self.call(source_menu:, adopter:, base_name:)
      name = uniquify_menu_name(adopter, base_name.to_s.strip)
      recipe_map = {}
      source_menu.menu_entries.where.not(recipe_id: nil).distinct.pluck(:recipe_id).compact.each do |rid|
        src = Recipe.find(rid)
        recipe_map[rid] = DuplicateRecipeForAdopter.call(source_recipe: src, adopter: adopter).id
      end

      copy = Menu.new(user: adopter, name: name, publicly_shareable: false)
      CopyMenuEntriesFromSource.call(target_menu: copy, source_menu: source_menu, recipe_map: recipe_map)
      copy.save!
      copy
    end

    def self.uniquify_menu_name(adopter, base_name)
      raise ArgumentError, "base_name blank" if base_name.blank?

      norm = base_name.strip.downcase
      return base_name.strip unless adopter.menus.where(name_normalized: norm).exists?

      2.upto(2 + MAX_UNIQUIFY_ITERATIONS - 1) do |n|
        candidate = "#{base_name.strip} (#{n})"
        return candidate unless adopter.menus.where(name_normalized: candidate.strip.downcase).exists?
      end

      raise ArgumentError,
            "could not find a unique menu name after #{MAX_UNIQUIFY_ITERATIONS} attempts"
    end
  end
end
