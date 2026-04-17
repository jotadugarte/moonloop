class MenuEntry < ApplicationRecord
  belongs_to :menu
  belongs_to :recipe, optional: true

  validates :weekday, presence: true
  validates :meal_type, presence: true
  validates :menu_id, uniqueness: { scope: [ :weekday, :meal_type ] }

  validate :meal_type_must_be_known
  validate :weekday_must_be_well_formed
  validate :entry_content_must_be_present

  private

  def meal_type_must_be_known
    return if meal_type.blank?

    Menus::MealType.new(meal_type)
  rescue ArgumentError
    errors.add(:meal_type, :invalid)
  end

  def weekday_must_be_well_formed
    return if weekday.nil?

    Menus::Weekday.new(weekday)
  rescue ArgumentError
    errors.add(:weekday, :invalid)
  end

  def entry_content_must_be_present
    text = freeform_text.to_s.strip
    return if recipe_id.present? || text.present?

    errors.add(:base, :content_required)
  end
end
