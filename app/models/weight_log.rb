class WeightLog < ApplicationRecord
  belongs_to :user

  validates :weight_kg, :height_cm, :bmi, presence: true
  validates :weight_kg, numericality: { greater_than_or_equal_to: 20, less_than_or_equal_to: 500 }, allow_nil: true

  attr_readonly :weight_kg, :height_cm

  before_validation :compute_bmi, if: -> { weight_kg.present? && height_cm.present? }

  private

  def compute_bmi
    self.bmi = (weight_kg / (height_cm / 100.0) ** 2).round(2)
  end
end
