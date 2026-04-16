class UserHabit < ApplicationRecord
  belongs_to :user
  belongs_to :habit_category
  belongs_to :global_habit_template, optional: true

  has_many :habit_completions, dependent: :destroy

  validates :name, :name_normalized, presence: true
  validates :frequency_type, presence: true
  validates :frequency_type, inclusion: { in: %w[daily weekdays every_x_days monthly] }

  normalizes :name, with: -> { _1.strip }
  normalizes :name_normalized, with: -> { _1.strip.downcase }

  before_validation :sync_name_normalized
  validate :active_name_must_be_unique_per_user, if: -> { user_id.present? && active? && name_normalized.present? }
  validate :frequency_params_shape
  validate :frequency_requirements

  def next_occurrence_after(date)
    Habits::NextOccurrence.after(user_habit: self, date: date)
  end

  private

  def sync_name_normalized
    return if name.blank?
    self.name_normalized = name.strip.downcase
  end

  def frequency_params_shape
    return if frequency_params.is_a?(Hash)
    errors.add(:frequency_params, :must_be_object)
  end

  def frequency_requirements
    case frequency_type
    when "daily"
      # no-op
    when "weekdays"
      weekdays = frequency_params.is_a?(Hash) ? frequency_params["weekdays"] : nil
      ok = weekdays.is_a?(Array) && weekdays.any? && weekdays.all? { |v| v.is_a?(Integer) && v.between?(0, 6) }
      errors.add(:frequency_params, :invalid_weekdays) unless ok
    when "every_x_days"
      interval = frequency_params.is_a?(Hash) ? frequency_params["interval"] : nil
      errors.add(:frequency_params, :invalid_interval) unless interval.is_a?(Integer) && interval >= 1
      errors.add(:activation_date, :blank) if activation_date.blank?
    when "monthly"
      errors.add(:activation_date, :blank) if activation_date.blank?
    else
      errors.add(:frequency_type, :inclusion)
    end
  end

  def active_name_must_be_unique_per_user
    relation = self.class.where(user_id: user_id, active: true, name_normalized: name_normalized)
    relation = relation.where.not(id: id) if persisted?
    return unless relation.exists?
    errors.add(:name, :taken)
  end
end
