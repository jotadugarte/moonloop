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
      @meal_type_key = Menus::MealType.new(meal_type).key
    end

    def call
      return nil if @entry.blank?
      return nil unless slot_preview_visible?

      dish = @entry.dish
      if dish&.image&.attached?
        Result.new(display: :uploaded, uploaded_image: dish.image, fallback_asset_path: nil)
      else
        Result.new(
          display: :fallback,
          uploaded_image: nil,
          fallback_asset_path: "menus/fallback_#{@meal_type_key}.svg"
        )
      end
    end

    private

    def slot_preview_visible?
      @entry.dish_id.present? || @entry.freeform_text.to_s.strip.present?
    end
  end
end
