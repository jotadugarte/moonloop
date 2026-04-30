# frozen_string_literal: true

class PhasesAdoptionSyncController < ApplicationController
  before_action :set_phase

  def accept_source_update
    Phases::ApplyAdoptionSourceSync.call(
      copy: @phase,
      expected_origin_fingerprint: params[:expected_origin_fingerprint].presence
    )
    redirect_to phase_path, notice: t("phases.flash.source_sync_applied")
  rescue Phases::ApplyAdoptionSourceSync::Error => e
    redirect_to phase_path, alert: t("phases.adoption_sync.errors.#{e.key}")
  end

  private

  def set_phase
    @phase = Current.user.phases.find(params[:id])
  end
end

