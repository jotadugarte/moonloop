class HabitCategory < ApplicationRecord
  belongs_to :user
  has_many :user_habits, dependent: :restrict_with_error

  validates :name, :name_normalized, presence: true
  validates :name_normalized, uniqueness: { scope: :user_id }

  normalizes :name, with: -> { _1.strip }
  normalizes :name_normalized, with: -> { _1.strip.downcase }

  before_validation :sync_name_normalized

  before_destroy :prevent_destroy_if_referenced

  private

  def sync_name_normalized
    return if name.blank?
    self.name_normalized = name.strip.downcase
  end

  def prevent_destroy_if_referenced
    return unless user_habits.exists?
    errors.add(:base, "cannot delete a category that has habits")
    throw(:abort)
  end
end

