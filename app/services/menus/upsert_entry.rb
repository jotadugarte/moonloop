module Menus
  class UpsertEntry
    def self.call(user:, menu:, weekday:, meal_type:, dish_id:, freeform_text:)
      new.call(
        user: user,
        menu: menu,
        weekday: weekday,
        meal_type: meal_type,
        dish_id: dish_id,
        freeform_text: freeform_text
      )
    end

    def call(user:, menu:, weekday:, meal_type:, dish_id:, freeform_text:)
      raise ArgumentError, "user is required" if user.blank?
      raise ArgumentError, "menu is required" if menu.blank?
      raise ArgumentError, "menu ownership mismatch" if menu.user_id != user.id

      wday = Menus::Weekday.new(weekday).value
      mtype = Menus::MealType.new(meal_type).key

      entry = MenuEntry.find_or_initialize_by(menu: menu, weekday: wday, meal_type: mtype)
      did = dish_id.present? ? dish_id.to_i : nil
      text = freeform_text.to_s.strip
      text = nil if text.blank?
      text = nil unless user.allow_menu_freeform

      if did.nil? && text.nil?
        if entry.persisted? && !user.allow_menu_freeform && entry.dish_id.blank? && entry.freeform_text.present?
          entry.errors.add(:base, :recipes_only_require_recipe_or_clear)
          raise ActiveRecord::RecordInvalid.new(entry)
        end

        entry.destroy! if entry.persisted?
        return :cleared
      end

      entry.dish_id = did
      entry.freeform_text = text
      entry.save!

      :ok
    end
  end
end
