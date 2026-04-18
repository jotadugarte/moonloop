# frozen_string_literal: true

class AddSourceExerciseRoutineToExerciseRoutines < ActiveRecord::Migration[8.1]
  def change
    add_reference :exercise_routines, :source_exercise_routine, foreign_key: { to_table: :exercise_routines }, null: true

    add_index :exercise_routines, %i[user_id source_exercise_routine_id],
      unique: true,
      where: "source_exercise_routine_id IS NOT NULL",
      name: "index_exercise_routines_adoption_unique_per_user_and_source"
  end
end
