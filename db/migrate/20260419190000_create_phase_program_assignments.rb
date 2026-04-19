# frozen_string_literal: true

class CreatePhaseProgramAssignments < ActiveRecord::Migration[8.1]
  def change
    create_table :phase_program_assignments do |t|
      t.references :phase_program, null: false, foreign_key: true
      t.references :menu, null: false, foreign_key: true
      t.references :exercise_routine, null: false, foreign_key: true
      t.integer :start_week, null: false
      t.integer :end_week, null: false

      t.timestamps
    end

    add_index :phase_program_assignments,
      %i[phase_program_id start_week end_week],
      name: "index_phase_program_assignments_on_program_and_range"

    add_check_constraint :phase_program_assignments, "start_week >= 1",
      name: "phase_program_assignments_start_week_gte_one"
    add_check_constraint :phase_program_assignments, "end_week >= start_week",
      name: "phase_program_assignments_end_gte_start"
  end
end
