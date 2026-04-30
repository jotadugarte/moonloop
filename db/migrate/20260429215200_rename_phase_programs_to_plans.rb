# frozen_string_literal: true

class RenamePhaseProgramsToPlans < ActiveRecord::Migration[8.1]
  def change
    rename_table :phase_programs, :plans
    rename_table :phase_program_assignments, :plan_assignments

    rename_column :plans, :source_phase_program_id, :source_plan_id

    rename_column :plan_assignments, :phase_program_id, :plan_id

    rename_index_if_exists(
      :plans,
      "index_phase_programs_on_user_and_name_normalized",
      "index_plans_on_user_and_name_normalized"
    )
    rename_index_if_exists(
      :plans,
      "index_phase_programs_on_source_phase_program_id",
      "index_plans_on_source_plan_id"
    )
    rename_index_if_exists(
      :plans,
      "index_phase_programs_adoption_unique_per_user_and_source",
      "index_plans_adoption_unique_per_user_and_source"
    )

    rename_index_if_exists(
      :plan_assignments,
      "index_phase_program_assignments_on_phase_program_id",
      "index_plan_assignments_on_plan_id"
    )
    rename_index_if_exists(
      :plan_assignments,
      "index_phase_program_assignments_on_program_and_range",
      "index_plan_assignments_on_plan_and_range"
    )

    # Rails migration API does not support renaming check constraints portably.
    # Keeping existing check constraint names is acceptable; behavior is unchanged.
  end

  private

  def rename_index_if_exists(table, old_name, new_name)
    return unless index_name_exists?(table, old_name)

    rename_index table, old_name, new_name
  end
end
