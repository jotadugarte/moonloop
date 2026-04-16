class ProvisionDefaultHabitsJob < ApplicationJob
  queue_as :default

  MAX_DEADLOCK_RETRIES = 2

  retry_on ActiveRecord::Deadlocked, attempts: MAX_DEADLOCK_RETRIES

  DEFAULT_TEMPLATE_CATALOG = {
    "nutrition_breakfast" => "Nutrition",
    "nutrition_lunch" => "Nutrition",
    "nutrition_dinner" => "Nutrition",
    "nutrition_snack" => "Nutrition",
    "fitness_exercise" => "Fitness",
    "fitness_water" => "Fitness",
    "emotional_pet" => "Emotional"
  }.freeze

  def self.default_template_codes
    DEFAULT_TEMPLATE_CATALOG.keys
  end

  # REQ-HABITS-005
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
      category = find_or_create_category!(user, DEFAULT_TEMPLATE_CATALOG.fetch(code))
      find_or_create_user_habit!(user, category, template)
    end
  end

  def find_or_create_category!(user, category_name)
    normalized = category_name.strip.downcase
    HabitCategory.find_or_create_by!(user: user, name_normalized: normalized) do |category|
      category.name = category_name
    end
  end

  def find_or_create_user_habit!(user, category, template)
    UserHabit.find_or_create_by!(user: user, global_habit_template: template) do |habit|
      habit.habit_category = category
      habit.name = template.code.humanize
      habit.name_normalized = habit.name.strip.downcase
      habit.active = true
      habit.frequency_type = "daily"
      habit.frequency_params = {}
      habit.activation_date = nil
    end
  end
end

