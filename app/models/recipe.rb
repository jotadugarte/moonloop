class Recipe < ApplicationRecord
  belongs_to :user

  has_many :menu_entries, dependent: :destroy

  has_one_attached :image

  validates :name, presence: true
  validates :meal_type, inclusion: { in: Menus::MealType::KEYS }

  normalizes :name, with: -> { _1.strip }
end
