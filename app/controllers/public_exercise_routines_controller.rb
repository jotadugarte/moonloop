# frozen_string_literal: true

class PublicExerciseRoutinesController < ApplicationController
  include AdoptionInvalidRecordFlash
  include CatalogPublicIndexSort

  before_action :set_public_routine, only: %i[show adopt]

  def index
    base = ExerciseRoutine.where(publicly_shareable: true)
    filtered = Catalog::ApplyPublicListingFilters.call(base, params)
    @routines = filtered.includes(:user).order(catalog_public_index_order)
  end

  def show
  end

  def adopt
    copy = ExerciseRoutines::AdoptFromPublicCatalog.call(
      adopter: Current.user,
      source: @routine,
      chosen_name: params.require(:name)
    )
    redirect_to edit_exercise_routine_path(copy), notice: t("public_exercise_routines.adopt.success")
  rescue ExerciseRoutines::AdoptFromPublicCatalog::Error => e
    redirect_to public_exercise_routine_path(@routine),
      alert: t("public_exercise_routines.adopt.errors.#{e.key}")
  rescue ActionController::ParameterMissing
    redirect_to public_exercise_routine_path(@routine),
      alert: t("public_exercise_routines.adopt.errors.name_blank")
  rescue ActiveRecord::RecordInvalid => e
    redirect_to public_exercise_routine_path(@routine), alert: adoption_invalid_alert_for(e.record)
  end

  private

  def set_public_routine
    @routine = ExerciseRoutine.find_by!(publicly_shareable: true, id: params[:id])
  end
end
