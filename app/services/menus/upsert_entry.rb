module Menus
  class UpsertEntry
    def self.call(user:, menu:, weekday:, meal_type:, recipe_id:, freeform_text:)
      new.call(
        user: user,
        menu: menu,
        weekday: weekday,
        meal_type: meal_type,
        recipe_id: recipe_id,
        freeform_text: freeform_text
      )
    end

    def call(user:, menu:, weekday:, meal_type:, recipe_id:, freeform_text:)
      raise ArgumentError, "user is required" if user.blank?
      raise ArgumentError, "menu is required" if menu.blank?
      raise ArgumentError, "menu ownership mismatch" if menu.user_id != user.id

      wday = Menus::Weekday.new(weekday).value
      mtype = Menus::MealType.new(meal_type).key

      entry = MenuEntry.find_or_initialize_by(menu: menu, weekday: wday, meal_type: mtype)
      rid = recipe_id.present? ? recipe_id.to_i : nil
      text = freeform_text.to_s.strip
      text = nil if text.blank?

      if rid.nil? && text.nil?
        entry.destroy! if entry.persisted?
        return :cleared
      end

      entry.recipe_id = rid
      entry.freeform_text = text
      entry.save!

      :ok
    end
  end
end
