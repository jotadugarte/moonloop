# frozen_string_literal: true

module Admin
  class DishesController < BaseController
    def revoke_public_share
      dish = Dish.where(publicly_shareable: true).find(params[:id])
      dish.update!(publicly_shareable: false)

      redirect_to public_dishes_path, notice: t("admin.moderation.dish.revoked_public_share")
    end
  end
end
