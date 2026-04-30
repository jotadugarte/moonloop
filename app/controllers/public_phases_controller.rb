# frozen_string_literal: true

class PublicPhasesController < ApplicationController
  include AdoptionInvalidRecordFlash
  include CatalogPublicIndexSort

  before_action :set_public_phase, only: %i[show adopt]

  def index
    base = Phase.where(publicly_shareable: true)
    filtered = Catalog::ApplyPublicListingFilters.call(base, params)
    @phases = filtered.includes(:user).order(catalog_public_index_order)
  end

  def show
  end

  def adopt
    copy = Phases::AdoptFromPublicCatalog.call(
      adopter: Current.user,
      source: @phase,
      chosen_name: params.require(:name)
    )
    redirect_to public_phase_path(@phase), notice: t("public_phases.adopt.success")
  rescue Phases::AdoptFromPublicCatalog::Error => e
    redirect_to public_phase_path(@phase),
      alert: t("public_phases.adopt.errors.#{e.key}")
  rescue ActionController::ParameterMissing
    redirect_to public_phase_path(@phase),
      alert: t("public_phases.adopt.errors.name_blank")
  rescue ActiveRecord::RecordInvalid => e
    redirect_to public_phase_path(@phase), alert: adoption_invalid_alert_for(e.record)
  end

  private

  def set_public_phase
    @phase = Phase.find_by!(publicly_shareable: true, id: params[:id])
  end
end

