# frozen_string_literal: true

module Admin
  class PhaseProgramsController < BaseController
    def revoke_public_share
      program = PhaseProgram.where(publicly_shareable: true).find(params[:id])
      program.update!(publicly_shareable: false)

      redirect_to public_phase_programs_path, notice: t("admin.moderation.phase_program.revoked_public_share")
    end
  end
end
