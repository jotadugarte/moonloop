# frozen_string_literal: true

class PhaseProgramsController < ApplicationController
  before_action :set_phase_program, only: %i[edit update destroy apply]

  def index
    @phase_programs = Current.user.phase_programs.order(:name)
    @phase_program = PhaseProgram.new
  end

  def create
    @phase_program = Current.user.phase_programs.new(phase_program_params)
    if @phase_program.save
      redirect_to edit_phase_program_path(@phase_program), notice: t("phase_programs.flash.created")
    else
      @phase_programs = Current.user.phase_programs.order(:name)
      render :index, status: :unprocessable_entity
    end
  end

  def edit
    @assignments = @phase_program.phase_program_assignments.order(:start_week, :id)
  end

  def update
    if @phase_program.update(phase_program_params)
      redirect_to edit_phase_program_path(@phase_program), notice: t("phase_programs.flash.updated")
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @phase_program.destroy!
    redirect_to phase_programs_path, notice: t("phase_programs.flash.destroyed")
  end

  def apply
    Programs::ApplyBundleToUser.call(phase_program: @phase_program, user: Current.user)
    redirect_to edit_phase_program_path(@phase_program), notice: t("phase_programs.flash.applied")
  rescue Programs::ApplyBundleToUser::Error
    redirect_to edit_phase_program_path(@phase_program), alert: t("phase_programs.flash.apply_failed")
  end

  private

  def set_phase_program
    @phase_program = Current.user.phase_programs.find(params[:id])
  end

  def phase_program_params
    params.require(:phase_program).permit(:name, :publicly_shareable)
  end
end
