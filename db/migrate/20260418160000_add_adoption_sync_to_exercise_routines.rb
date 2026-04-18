# frozen_string_literal: true

class AddAdoptionSyncToExerciseRoutines < ActiveRecord::Migration[8.1]
  def up
    add_column :exercise_routines, :source_sync_fingerprint, :string
    add_column :exercise_routines, :adoption_catalog_origin_id, :integer

    ExerciseRoutine.reset_column_information
    ExerciseRoutine.where.not(source_exercise_routine_id: nil).find_each do |routine|
      src = ExerciseRoutine.find_by(id: routine.source_exercise_routine_id)
      next unless src

      routine.update_columns(
        adoption_catalog_origin_id: routine.source_exercise_routine_id,
        source_sync_fingerprint: ExerciseRoutines::ContentFingerprint.for_routine(src)
      )
    end
  end

  def down
    remove_column :exercise_routines, :adoption_catalog_origin_id
    remove_column :exercise_routines, :source_sync_fingerprint
  end
end
