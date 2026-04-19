# frozen_string_literal: true

class AddSuggestedMetricsToGlobalHabitTemplates < ActiveRecord::Migration[8.1]
  def change
    add_column :global_habit_templates, :suggested_habit_metric_kind, :string, null: false, default: "none"
    add_column :global_habit_templates, :suggested_daily_target, :integer, null: false, default: 1

    reversible do |dir|
      dir.up do
        GlobalHabitTemplate.reset_column_information
        {
          "fitness_water" => { kind: "count", target: 8 },
          "fitness_exercise" => { kind: "duration_min", target: 30 }
        }.each do |code, cfg|
          GlobalHabitTemplate.where(code: code).update_all(
            suggested_habit_metric_kind: cfg[:kind],
            suggested_daily_target: cfg[:target]
          )
        end
      end
    end
  end
end
