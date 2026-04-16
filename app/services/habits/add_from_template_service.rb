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
      habit.save
      habit
    end
  end
end
