# frozen_string_literal: true

class AddPhaseAssignmentCheckConstraints < ActiveRecord::Migration[8.1]
  def change
    add_check_constraint :phase_assignments, "start_week >= 1", name: "phase_assignments_start_week_gte_one"
    add_check_constraint :phase_assignments, "end_week >= start_week", name: "phase_assignments_end_gte_start"
  end
end
