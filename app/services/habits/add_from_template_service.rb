# frozen_string_literal: true

module Habits
  class AddFromTemplateService
    def initialize(user:, template:, category:)
      @user = user
      @template = template
      @category = category
    end

    def call
      habit = @user.user_habits.find_or_initialize_by(global_habit_template: @template)
      habit.habit_category = @category
      habit.name = I18n.t("habits.templates.#{@template.code}.name", default: @template.code.humanize)
      habit.active = true
      if habit.new_record?
        habit.frequency_type = "daily"
        habit.frequency_params = {}
        habit.activation_date = nil
        habit.habit_metric_kind = @template.suggested_habit_metric_kind
        habit.daily_target =
          @template.suggested_habit_metric_kind == "none" ? 1 : @template.suggested_daily_target
      end
      habit.save
      habit
    end
  end
end
