# frozen_string_literal: true

# User-owned reusable Phase templates (weeks + blocks); distinct from GET /phase (program dashboard).
class UserPhasesController < ApplicationController
  before_action :set_phase, only: %i[edit update destroy]

  def index
    @phases = Current.user.phases.order(:name)
    @phase = Phase.new
  end

  def create
    @phase = Current.user.phases.new(phase_params)
    return redirect_after_create if @phase.save

    index_for_create_failure
  end

  def edit
  end

  def update
    return redirect_after_update if @phase.update(phase_params)

    render :edit, status: :unprocessable_content
  end

  def destroy
    @phase.destroy!
    redirect_to user_phases_path, notice: t("user_phases.flash.destroyed")
  end

  private

  def redirect_after_create
    redirect_to edit_user_phase_path(@phase), notice: t("user_phases.flash.created")
  end

  def index_for_create_failure
    @phases = Current.user.phases.order(:name)
    render :index, status: :unprocessable_content
  end

  def redirect_after_update
    redirect_to edit_user_phase_path(@phase), notice: t("user_phases.flash.updated")
  end

  def set_phase
    @phase = Current.user.phases.find(params[:id])
  end

  def phase_params
    params.require(:phase).permit(
      :name,
      :weeks_total,
      :publicly_shareable,
      catalog_listing_facet_attributes: %i[
        id goal_phrase difficulty_level normalized_tags duration_weeks_min duration_weeks_max
      ]
    )
  end
end
