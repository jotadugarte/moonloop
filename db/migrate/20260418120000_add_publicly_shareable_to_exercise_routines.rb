# frozen_string_literal: true

class AddPubliclyShareableToExerciseRoutines < ActiveRecord::Migration[8.1]
  def change
    add_column :exercise_routines, :publicly_shareable, :boolean, default: false, null: false
  end
end
