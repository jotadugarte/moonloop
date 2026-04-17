# frozen_string_literal: true

class ExerciseRoutinesController < ApplicationController
  before_action :set_routine, only: %i[edit update destroy confirm_destroy duplicate]

  def index
    @routine = Current.user.exercise_routines.new
    @routine.exercise_routine_lines.build(weekday: 0, position: 0)
    @routines = Current.user.exercise_routines.order(:name)
  end

  def create
    @routine = Current.user.exercise_routines.new(routine_params)
    @routines = Current.user.exercise_routines.order(:name)

    if @routine.save
      redirect_to exercise_routines_path, notice: t("exercise_routines.flash.created")
    else
      @routine.exercise_routine_lines.build(weekday: 0, position: 0) if @routine.exercise_routine_lines.empty?
      render :index, status: :unprocessable_entity
    end
  end

  def edit
    apply_add_line_if_requested
  end

  def update
    if @routine.update(routine_params)
      redirect_to edit_exercise_routine_path(@routine), notice: t("exercise_routines.flash.updated")
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def confirm_destroy
    @assignment_count = @routine.exercise_routine_assignments.count
  end

  def destroy
    ExerciseRoutines::DestroyRoutine.call(routine: @routine)
    redirect_to exercise_routines_path, notice: t("exercise_routines.flash.destroyed")
  end

  def duplicate
    copy = ExerciseRoutines::DuplicateRoutine.call(source: @routine, new_name: params[:new_name])
    redirect_to edit_exercise_routine_path(copy), notice: t("exercise_routines.flash.duplicated")
  rescue ActiveRecord::RecordInvalid
    redirect_to exercise_routines_path, alert: t("exercise_routines.flash.duplicate_failed")
  end

  private

  def set_routine
    @routine = Current.user.exercise_routines.find(params[:id])
  end

  def apply_add_line_if_requested
    return unless params[:add_line].present?

    w = params.fetch(:weekday, 0).to_i.clamp(0, 6)
    max_p = @routine.exercise_routine_lines.reject(&:marked_for_destruction?)
      .select { |l| l.weekday == w }.map(&:position).compact.max
    next_p = max_p.nil? ? 0 : max_p + 1
    @routine.exercise_routine_lines.build(
      weekday: w,
      position: next_p,
      label: I18n.t("exercise_routines.edit.placeholder_line_label")
    )
  end

  def routine_params
    params.require(:exercise_routine).permit(
      :name,
      exercise_routine_lines_attributes: %i[id weekday position label notes _destroy]
    )
  end
end
