class MenuEntry < ApplicationRecord
  belongs_to :menu
  belongs_to :recipe, optional: true, foreign_key: :dish_id, inverse_of: :menu_entries

  alias_attribute :recipe_id, :dish_id

  validates :weekday, presence: true
  validates :meal_type, presence: true
  validates :menu_id, uniqueness: { scope: [ :weekday, :meal_type ] }

  validate :meal_type_must_be_known
  validate :weekday_must_be_well_formed
  validate :entry_content_must_be_present, unless: :should_skip_entry_content_validation?
  validate :recipe_must_belong_to_menu_owner

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

  def recipe_must_belong_to_menu_owner
    return if recipe_id.blank? || menu.blank?

    return if recipe&.user_id == menu.user_id

    errors.add(:recipe_id, :must_match_menu_owner)
  end

  def should_skip_entry_content_validation?
    marked_for_destruction?
  end
end
