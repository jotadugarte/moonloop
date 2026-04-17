# frozen_string_literal: true

class PhaseAssignmentsController < ApplicationController
  before_action :set_assignment, only: %i[edit update destroy]

  def new
    @assignment = Current.user.phase_assignments.new
  end

  def create
    @assignment = Current.user.phase_assignments.new(assignment_params)

    if @assignment.save
      redirect_to phase_path, notice: t("phase_assignments.flash.created")
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @assignment.update(assignment_params)
      redirect_to phase_path, notice: t("phase_assignments.flash.updated")
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @assignment.destroy!
    redirect_to phase_path, notice: t("phase_assignments.flash.destroyed")
  end

  private

  def set_assignment
    @assignment = Current.user.phase_assignments.find(params[:id])
  end

  def assignment_params
    params.require(:phase_assignment).permit(:menu_id, :start_week, :end_week)
  end
end
