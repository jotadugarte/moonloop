# frozen_string_literal: true

module Menus
  class DuplicateRecipeForAdopter
    def self.call(source_recipe:, adopter:)
      copy = Recipe.new(
        user: adopter,
        name: source_recipe.name,
        instructions: source_recipe.instructions.to_s,
        publicly_shareable: false
      )
      copy.save!
      if source_recipe.image.attached?
        copy.image.attach(source_recipe.image.blob)
      end
      copy
    end
  end
end
