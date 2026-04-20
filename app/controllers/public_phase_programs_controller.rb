# frozen_string_literal: true

class PublicPhaseProgramsController < ApplicationController
  include AdoptionInvalidRecordFlash
  include CatalogPublicIndexSort

  before_action :set_public_program, only: %i[show adopt]

  def index
    @programs = PhaseProgram.includes(:user).where(publicly_shareable: true).order(catalog_public_index_order)
  end

  def show
    @assignments = @program.phase_program_assignments.includes(:menu, :exercise_routine).order(:start_week, :id)
  end

  def adopt
    copy = Programs::AdoptFromPublicCatalog.call(
      adopter: Current.user,
      source: @program,
      chosen_name: params.require(:name)
    )
    redirect_to edit_phase_program_path(copy), notice: t("public_phase_programs.adopt.success")
  rescue Programs::AdoptFromPublicCatalog::Error => e
    redirect_to public_phase_program_path(@program),
      alert: t("public_phase_programs.adopt.errors.#{e.key}")
  rescue ActionController::ParameterMissing
    redirect_to public_phase_program_path(@program),
      alert: t("public_phase_programs.adopt.errors.name_blank")
  rescue ActiveRecord::RecordInvalid => e
    redirect_to public_phase_program_path(@program), alert: adoption_invalid_alert_for(e.record)
  end

  private

  def set_public_program
    @program = PhaseProgram.find_by!(publicly_shareable: true, id: params[:id])
  end
end
