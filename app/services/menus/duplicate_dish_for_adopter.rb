# frozen_string_literal: true

module Menus
  class DuplicateDishForAdopter
    def self.call(source_dish:, adopter:)
      copy = Dish.new(
        user: adopter,
        name: source_dish.name,
        instructions: source_dish.instructions.to_s,
        meal_type: source_dish.meal_type,
        publicly_shareable: false
      )
      copy.save!
      if source_dish.image.attached?
        copy.image.attach(source_dish.image.blob)
      end
      copy
    end
  end
end
