class ProvisionDefaultHabitsJob < ApplicationJob
  queue_as :default

  MAX_DEADLOCK_RETRIES = 2
  MAX_RECORD_NOT_UNIQUE_RETRIES = 3

  retry_on ActiveRecord::Deadlocked, attempts: MAX_DEADLOCK_RETRIES
  retry_on ActiveRecord::RecordNotUnique, attempts: MAX_RECORD_NOT_UNIQUE_RETRIES

  DEFAULT_TEMPLATE_CATALOG = {
    "nutrition_breakfast" => "nutrition",
    "nutrition_lunch" => "nutrition",
    "nutrition_dinner" => "nutrition",
    "nutrition_snack" => "nutrition",
    "fitness_exercise" => "fitness",
    "fitness_water" => "fitness",
    "emotional_pet" => "emotional"
  }.freeze

  def self.default_template_codes
    DEFAULT_TEMPLATE_CATALOG.keys
  end

  # [REQ-HAB-002]
  def perform(user_id:)
    user = User.find(user_id)
    raise ArgumentError, "user must exist" unless user.persisted?

    templates = provision_templates!
    provision_user_habits!(user, templates)
  end

  private

  def provision_templates!
    self.class.default_template_codes.index_with do |code|
      GlobalHabitTemplate.find_or_create_by!(code: code)
    end
  end

  def provision_user_habits!(user, templates)
    templates.each do |code, template|
      category_key = DEFAULT_TEMPLATE_CATALOG.fetch(code)
      category_name = I18n.t("habits.default_categories.#{category_key}.name")
      category = find_or_create_category!(user, category_name)
      find_or_create_user_habit!(user, category, template)
    end
  end

  def find_or_create_category!(user, category_name)
    normalized = category_name.strip.downcase
    HabitCategory.find_or_create_by!(user: user, name_normalized: normalized) do |category|
      category.name = category_name
    end
  rescue ActiveRecord::RecordNotUnique
    HabitCategory.find_by!(user: user, name_normalized: normalized)
  end

  def find_or_create_user_habit!(user, category, template)
    UserHabit.find_or_create_by!(user: user, global_habit_template: template) do |habit|
      habit.habit_category = category
      habit.name = I18n.t("habits.templates.#{template.code}.name", default: template.code.humanize)
      habit.name_normalized = habit.name.strip.downcase
      habit.active = true
      habit.frequency_type = "daily"
      habit.frequency_params = {}
      habit.activation_date = nil
    end
  rescue ActiveRecord::RecordNotUnique
    UserHabit.find_by!(user: user, global_habit_template: template)
  end
end

