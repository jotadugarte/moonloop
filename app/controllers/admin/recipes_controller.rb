module Admin
  class RecipesController < BaseController
    def revoke_public_share
      recipe = Recipe.where(publicly_shareable: true).find(params[:id])
      recipe.update!(publicly_shareable: false)

      redirect_to public_dishes_path, notice: t("admin.moderation.recipe.revoked_public_share")
    end
  end
end
