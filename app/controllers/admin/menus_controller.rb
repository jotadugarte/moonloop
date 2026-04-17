module Admin
  class MenusController < BaseController
    def revoke_public_share
      menu = Menu.find(params[:id])
      menu.update!(publicly_shareable: false)

      redirect_to public_recipes_path, notice: t("admin.moderation.menu.revoked_public_share")
    end
  end
end
