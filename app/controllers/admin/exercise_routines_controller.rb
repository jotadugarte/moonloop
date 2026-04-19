# frozen_string_literal: true

module Admin
  class ExerciseRoutinesController < BaseController
    def revoke_public_share
      routine = ExerciseRoutine.where(publicly_shareable: true).find(params[:id])
      routine.update!(publicly_shareable: false)

      redirect_to public_exercise_routines_path, notice: t("admin.moderation.exercise_routine.revoked_public_share")
    end
  end
end
