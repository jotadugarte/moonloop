class Recipe < ApplicationRecord
  belongs_to :user

  has_many :menu_entries, dependent: :destroy

  has_one_attached :image

  validates :name, presence: true
  validates :meal_type, inclusion: { in: Menus::MealType::KEYS }
  validate :image_upload_safety_limits

  normalizes :name, with: -> { _1.strip }

  private

  def image_upload_safety_limits
    return unless image.attached?
    return if image.blob&.content_type == "image/svg+xml"

    result = ImageUploads::SafetyLimits.validate(image.blob)
    return unless result.rejected?

    result.errors.each { errors.add(:image, _1) }
  end
end
