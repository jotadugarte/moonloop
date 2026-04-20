class UserHabit < ApplicationRecord
  METRIC_KINDS = %w[none count duration_min].freeze
  DAILY_TARGET_MAX = 99_999
  REMINDER_TIME_OF_DAY_REGEX = /\A\d{2}:\d{2}\z/

  belongs_to :user
  belongs_to :habit_category
  belongs_to :global_habit_template, optional: true

  has_many :habit_completions, dependent: :destroy
  has_many :habit_reminder_events, dependent: :destroy

  validates :name, :name_normalized, presence: true
  validates :frequency_type, presence: true
  validates :frequency_type, inclusion: { in: %w[daily weekdays every_x_days monthly] }
  validates :habit_metric_kind, inclusion: { in: METRIC_KINDS }
  validates :daily_target,
    numericality: {
      only_integer: true,
      greater_than_or_equal_to: 1,
      less_than_or_equal_to: DAILY_TARGET_MAX
    }

  normalizes :name, with: -> { _1.strip }
  normalizes :name_normalized, with: -> { _1.strip.downcase }

  before_validation :sync_name_normalized
  before_validation :normalize_habit_metrics
  before_update :mark_streak_counters_stale_on_metrics_change
  after_update_commit :enqueue_recompute_streak_counters_if_stale
  validate :active_name_must_be_unique_per_user, if: -> { user_id.present? && active? && name_normalized.present? }
  validate :frequency_params_shape
  validate :frequency_requirements
  validate :activation_date_locked_if_completions_exist, on: :update
  validate :reminder_configuration_rules

  def next_occurrence_after(date)
    Habits::NextOccurrence.after(user_habit: self, date: date)
  end

  private

  def normalize_habit_metrics
    self.habit_metric_kind = "none" if habit_metric_kind.blank?
    self.daily_target = 1 if habit_metric_kind == "none"
  end

  def sync_name_normalized
    return if name.blank?
    self.name_normalized = name.strip.downcase
  end

  def mark_streak_counters_stale_on_metrics_change
    return unless will_save_change_to_daily_target? || will_save_change_to_habit_metric_kind?

    self.streak_counters_stale = true
  end

  def enqueue_recompute_streak_counters_if_stale
    return unless saved_change_to_streak_counters_stale?
    return unless streak_counters_stale?

    Habits::RecomputeStreakCountersJob.perform_later(user_habit_id: id)
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

  def activation_date_locked_if_completions_exist
    return unless activation_date_changed?
    return if habit_completions.none?

    errors.add(:activation_date, :locked_when_completions_exist)
  end

  def reminder_configuration_rules
    return unless reminder_enabled?

    errors.add(:base, :reminder_not_allowed_when_inactive) unless active?

    if reminder_time_of_day.blank?
      errors.add(:reminder_time_of_day, :blank)
    elsif !REMINDER_TIME_OF_DAY_REGEX.match?(reminder_time_of_day)
      errors.add(:reminder_time_of_day, :invalid)
    else
      hour, minute = reminder_time_of_day.split(":").map(&:to_i)
      errors.add(:reminder_time_of_day, :invalid) unless hour.between?(0, 23) && minute.between?(0, 59)
    end

    return if reminder_email? || reminder_web_push?

    errors.add(:base, :reminder_requires_channel)
  end
end
