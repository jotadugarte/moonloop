class UserHabit < ApplicationRecord
  belongs_to :user
  belongs_to :habit_category
  belongs_to :global_habit_template, optional: true

  validates :name, :name_normalized, presence: true
  validates :active, inclusion: { in: [true, false] }

  normalizes :name, with: -> { _1.strip }
  normalizes :name_normalized, with: -> { _1.strip.downcase }

  before_validation :sync_name_normalized
  validate :active_name_must_be_unique_per_user, if: -> { user_id.present? && active? && name_normalized.present? }

  private

  def sync_name_normalized
    return if name.blank?
    self.name_normalized = name.strip.downcase
  end

  def active_name_must_be_unique_per_user
    relation = self.class.where(user_id: user_id, active: true, name_normalized: name_normalized)
    relation = relation.where.not(id: id) if persisted?
    return unless relation.exists?
    errors.add(:name, "has already been taken")
  end
end

