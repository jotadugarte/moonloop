class WeightLog < ApplicationRecord
  belongs_to :user

  validates :weight_kg, :height_cm, :bmi, :logged_at, presence: true
  validates :weight_kg, numericality: { greater_than_or_equal_to: 20, less_than_or_equal_to: 500 }, allow_nil: true

  validate :logged_at_not_in_future

  attr_readonly :weight_kg, :height_cm

  scope :ordered_for_history, -> { order(logged_at: :desc, id: :desc) }

  before_validation :compute_bmi, if: -> { weight_kg.present? && height_cm.present? }

  private

  def logged_at_not_in_future
    return if logged_at.blank? || user.blank?

    Time.use_zone(user.timezone) do
      errors.add(:logged_at, :future_timestamp) if logged_at > Time.zone.now
    end
  end

  def compute_bmi
    self.bmi = (weight_kg / (height_cm / 100.0) ** 2).round(2)
  end
end
