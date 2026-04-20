# frozen_string_literal: true

class PublicPhaseProgramsController < ApplicationController
  before_action :set_public_program, only: %i[show]

  def index
    @programs = PhaseProgram.includes(:user).where(publicly_shareable: true).order(:name)
  end

  def show
    @assignments = @program.phase_program_assignments.includes(:menu, :exercise_routine).order(:start_week, :id)
  end

  private

  def set_public_program
    @program = PhaseProgram.find_by!(publicly_shareable: true, id: params[:id])
  end
end
