class ProfilesController < ApplicationController
  def edit
    @user = Current.user
  end

  def update
    @user = Current.user

    if @user.update(profile_params)
      redirect_to edit_profile_path, notice: t("profiles.update.success")
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def profile_params
    # height_cm is strictly excluded from these permitted attributes
    params.require(:user).permit(:date_of_birth, :timezone, :allow_menu_freeform, :body_unit_system)
  end
end
