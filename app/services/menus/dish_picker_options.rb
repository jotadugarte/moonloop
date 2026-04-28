# frozen_string_literal: true

module Menus
  class DishPickerOptions
    Result = Struct.new(:dishes, :dishes_by_meal_type, keyword_init: true)

    def self.call(user:)
      new(user: user).call
    end

    def initialize(user:)
      @user = user
    end

    def call
      dishes = @user.dishes.order(:name).to_a
      Result.new(dishes: dishes, dishes_by_meal_type: dishes.group_by(&:meal_type))
    end
  end
end
