# frozen_string_literal: true

class CreateExerciseRoutinesAndLines < ActiveRecord::Migration[8.1]
  def change
    create_table :exercise_routines do |t|
      t.references :user, null: false, foreign_key: true
      t.string :name, null: false
      t.string :name_normalized, null: false
      t.timestamps
    end

    add_index :exercise_routines, [ :user_id, :name_normalized ], unique: true, name: "index_exercise_routines_on_user_and_name_normalized"

    create_table :exercise_routine_lines do |t|
      t.references :exercise_routine, null: false, foreign_key: true
      t.integer :weekday, null: false
      t.integer :position, null: false
      t.string :label, null: false, limit: 500
      t.text :notes
      t.timestamps
    end

    add_index :exercise_routine_lines,
              [ :exercise_routine_id, :weekday, :position ],
              unique: true,
              name: "index_exercise_routine_lines_on_routine_weekday_position"
  end
end
