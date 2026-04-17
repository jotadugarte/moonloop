# frozen_string_literal: true

class CreateExerciseRoutineAssignments < ActiveRecord::Migration[8.1]
  def change
    create_table :exercise_routine_assignments do |t|
      t.references :user, null: false, foreign_key: true
      t.references :exercise_routine, null: false, foreign_key: true
      t.integer :start_week, null: false
      t.integer :end_week, null: false

      t.timestamps
    end

    add_index :exercise_routine_assignments,
              %i[user_id start_week end_week],
              name: "index_exercise_routine_assignments_on_user_and_range"

    add_check_constraint :exercise_routine_assignments, "start_week >= 1",
                         name: "exercise_routine_assignments_start_week_gte_one"
    add_check_constraint :exercise_routine_assignments, "end_week >= start_week",
                         name: "exercise_routine_assignments_end_gte_start"
  end
end
