# frozen_string_literal: true

class PlanAssignmentsController < ApplicationController
  before_action :set_plan
  before_action :set_assignment, only: %i[edit update destroy]

  def new
    @assignment = @plan.plan_assignments.new
  end

  def create
    @assignment = @plan.plan_assignments.new(assignment_params)
    if @assignment.save
      redirect_to edit_plan_path(@plan), notice: t("plan_assignments.flash.created")
    else
      render :new, status: :unprocessable_content
    end
  end

  def edit
  end

  def update
    if @assignment.update(assignment_params)
      redirect_to edit_plan_path(@plan), notice: t("plan_assignments.flash.updated")
    else
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    @assignment.destroy!
    redirect_to edit_plan_path(@plan), notice: t("plan_assignments.flash.destroyed")
  end

  private

  def set_plan
    @plan = Current.user.plans.find(params[:plan_id])
  end

  def set_assignment
    @assignment = @plan.plan_assignments.find(params[:id])
  end

  def assignment_params
    params.require(:plan_assignment).permit(:menu_id, :exercise_routine_id, :start_week, :end_week)
  end
end
