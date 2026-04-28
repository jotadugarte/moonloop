# frozen_string_literal: true

module Menus
  # Resolves which image to show in a menu grid slot: uploaded dish image or a
  # meal-type fallback asset (REQ-MENU-002, context-based).
  class SlotPreview
    Result = Struct.new(:display, :uploaded_image, :fallback_asset_path, keyword_init: true)

    def self.call(entry:, meal_type:)
      new(entry: entry, meal_type: meal_type).call
    end

    def initialize(entry:, meal_type:)
      @entry = entry
      @slot_meal_type_key = Menus::MealType.new(meal_type).key
    end

    def call
      return nil if @entry.blank?
      return nil unless slot_preview_visible?

      dish = @entry.dish
      return uploaded_result(dish) if show_uploaded_image?(dish)

      fallback_result(dish)
    end

    private

    def slot_preview_visible?
      @entry.dish_id.present? || @entry.freeform_text.to_s.strip.present?
    end

    def show_uploaded_image?(dish)
      dish&.image&.attached? && !placeholder_image?(dish)
    end

    def uploaded_result(dish)
      Result.new(display: :uploaded, uploaded_image: dish.image, fallback_asset_path: nil)
    end

    def fallback_result(dish)
      Result.new(
        display: :fallback,
        uploaded_image: nil,
        fallback_asset_path: "menus/fallback_#{fallback_meal_type_key(dish)}.svg"
      )
    end

    def fallback_meal_type_key(dish)
      return Menus::MealType.new(dish.meal_type).key if dish.present?

      @slot_meal_type_key
    end

    def placeholder_image?(dish)
      blob = dish&.image&.blob
      blob&.content_type == "image/svg+xml" && blob.filename.to_s.start_with?("fallback_")
    end
  end
end
