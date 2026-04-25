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
    return unless image_upload_needs_limits_check?

    ImageUploads::SafetyLimits
      .validate(image.blob)
      .errors
      .each { errors.add(:image, _1) }
  end

  def image_upload_needs_limits_check?
    return false unless image.attached?

    image.blob&.content_type != "image/svg+xml"
  end
end
