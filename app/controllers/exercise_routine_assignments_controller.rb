# frozen_string_literal: true

class ExerciseRoutineAssignmentsController < ApplicationController
  before_action :set_assignment, only: %i[edit update destroy]

  def new
    @assignment = Current.user.exercise_routine_assignments.new
  end

  def create
    @assignment = Current.user.exercise_routine_assignments.new(assignment_params)

    if @assignment.save
      redirect_to phase_path, notice: t("exercise_routine_assignments.flash.created")
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @assignment.update(assignment_params)
      redirect_to phase_path, notice: t("exercise_routine_assignments.flash.updated")
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @assignment.destroy!
    redirect_to phase_path, notice: t("exercise_routine_assignments.flash.destroyed")
  end

  private

  def set_assignment
    @assignment = Current.user.exercise_routine_assignments.find(params[:id])
  end

  def assignment_params
    params.require(:exercise_routine_assignment).permit(:exercise_routine_id, :start_week, :end_week)
  end
end
