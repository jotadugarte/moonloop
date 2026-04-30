# frozen_string_literal: true

module Admin
  class PlansController < BaseController
    def revoke_public_share
      plan = Plan.where(publicly_shareable: true).find(params[:id])
      plan.update!(publicly_shareable: false)

      redirect_to public_plans_path, notice: t("admin.moderation.plan.revoked_public_share")
    end
  end
end
