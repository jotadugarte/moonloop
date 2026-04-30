# frozen_string_literal: true

class PublicPlansController < ApplicationController
  include AdoptionInvalidRecordFlash
  include CatalogPublicIndexSort

  before_action :set_public_plan, only: %i[show adopt]

  def index
    base = Plan.where(publicly_shareable: true)
    filtered = Catalog::ApplyPublicListingFilters.call(base, params)
    @plans = filtered.includes(:user).order(catalog_public_index_order)
  end

  def show
    @assignments = @plan.plan_assignments.includes(:menu, :exercise_routine).order(:start_week, :id)
  end

  def adopt
    copy = Plans::AdoptFromPublicCatalog.call(
      adopter: Current.user,
      source: @plan,
      chosen_name: params.require(:name)
    )
    redirect_to edit_plan_path(copy), notice: t("public_plans.adopt.success")
  rescue Plans::AdoptFromPublicCatalog::Error => e
    redirect_to public_plan_path(@plan),
      alert: t("public_plans.adopt.errors.#{e.key}")
  rescue ActionController::ParameterMissing
    redirect_to public_plan_path(@plan),
      alert: t("public_plans.adopt.errors.name_blank")
  rescue ActiveRecord::RecordInvalid => e
    redirect_to public_plan_path(@plan), alert: adoption_invalid_alert_for(e.record)
  end

  private

  def set_public_plan
    @plan = Plan.find_by!(publicly_shareable: true, id: params[:id])
  end
end
