# frozen_string_literal: true

module Plans
  # Rebuilds +plan+ segment rows from +source+ (menus/routines duplicated for +adopter+).
  class PopulateAssignmentsFromSource
    def self.call(plan:, source:, adopter:, name_prefix:)
      plan.plan_assignments.destroy_all

      menu_map = {}
      routine_map = {}

      source.plan_assignments.order(:start_week, :id).each do |seg|
        menu_base = "#{name_prefix} — #{seg.menu.name}"
        menu_map[seg.menu_id] ||= Menus::CopyMenuForAdopter.call(
          source_menu: seg.menu,
          adopter: adopter,
          base_name: menu_base
        )

        routine_base = "#{name_prefix} — #{seg.exercise_routine.name}"
        routine_map[seg.exercise_routine_id] ||= ExerciseRoutines::CopyRoutineForAdopter.call(
          source: seg.exercise_routine,
          adopter: adopter,
          base_name: routine_base
        )

        plan.plan_assignments.create!(
          menu_id: menu_map[seg.menu_id].id,
          exercise_routine_id: routine_map[seg.exercise_routine_id].id,
          start_week: seg.start_week,
          end_week: seg.end_week
        )
      end
    end
  end
end
