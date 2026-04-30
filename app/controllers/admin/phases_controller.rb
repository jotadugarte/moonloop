# frozen_string_literal: true

module Admin
  class PhasesController < BaseController
    def revoke_public_share
      phase = Phase.where(publicly_shareable: true).find(params[:id])
      phase.update!(publicly_shareable: false)

      redirect_to public_phases_path, notice: t("admin.moderation.phase.revoked_public_share")
    end
  end
end

