# frozen_string_literal: true

class PlansController < ApplicationController
  before_action :set_plan, only: %i[edit update destroy apply accept_source_update]

  def index
    @plans = Current.user.plans.order(:name)
    @plan = Plan.new
  end

  def create
    @plan = Current.user.plans.new(plan_params)
    if @plan.save
      redirect_to edit_plan_path(@plan), notice: t("plans.flash.created")
    else
      @plans = Current.user.plans.order(:name)
      render :index, status: :unprocessable_content
    end
  end

  def edit
    set_adoption_sync_status
    load_edit_assignments
  end

  def update
    if @plan.update(plan_params)
      redirect_to edit_plan_path(@plan), notice: t("plans.flash.updated")
    else
      set_adoption_sync_status
      load_edit_assignments
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    @plan.destroy!
    redirect_to plans_path, notice: t("plans.flash.destroyed")
  end

  def apply
    Plans::ApplyToUser.call(plan: @plan, user: Current.user, phase_one_starts_on: params[:phase_one_starts_on])
    redirect_to edit_plan_path(@plan), notice: t("plans.flash.applied")
  rescue Plans::ApplyToUser::Error
    redirect_to edit_plan_path(@plan), alert: t("plans.flash.apply_failed")
  end

  def accept_source_update
    Plans::ApplyAdoptionSourceSync.call(
      copy: @plan,
      expected_origin_fingerprint: params[:expected_origin_fingerprint].presence
    )
    redirect_to edit_plan_path(@plan), notice: t("plans.flash.source_sync_applied")
  rescue Plans::ApplyAdoptionSourceSync::Error => e
    redirect_to edit_plan_path(@plan),
      alert: t("plans.adoption_sync.errors.#{e.key}")
  end

  private

  def set_adoption_sync_status
    @adoption_sync_status = Plans::AdoptionSyncStatus.for_plan(@plan)
  end

  def load_edit_assignments
    @assignments = @plan.plan_assignments.order(:start_week, :id)
  end

  def set_plan
    @plan = Current.user.plans.find(params[:id])
  end

  def plan_params
    params.require(:plan).permit(
      :name,
      :publicly_shareable,
      catalog_listing_facet_attributes: %i[
        id goal_phrase difficulty_level normalized_tags duration_weeks_min duration_weeks_max
      ]
    )
  end
end

