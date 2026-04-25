# frozen_string_literal: true

class PhaseProgramAssignmentsController < ApplicationController
  before_action :set_phase_program
  before_action :set_assignment, only: %i[edit update destroy]

  def new
    @assignment = @phase_program.phase_program_assignments.new
  end

  def create
    @assignment = @phase_program.phase_program_assignments.new(assignment_params)
    if @assignment.save
      redirect_to edit_phase_program_path(@phase_program), notice: t("phase_program_assignments.flash.created")
    else
      render :new, status: :unprocessable_content
    end
  end

  def edit
  end

  def update
    if @assignment.update(assignment_params)
      redirect_to edit_phase_program_path(@phase_program), notice: t("phase_program_assignments.flash.updated")
    else
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    @assignment.destroy!
    redirect_to edit_phase_program_path(@phase_program), notice: t("phase_program_assignments.flash.destroyed")
  end

  private

  def set_phase_program
    @phase_program = Current.user.phase_programs.find(params[:phase_program_id])
  end

  def set_assignment
    @assignment = @phase_program.phase_program_assignments.find(params[:id])
  end

  def assignment_params
    params.require(:phase_program_assignment).permit(:menu_id, :exercise_routine_id, :start_week, :end_week)
  end
end
