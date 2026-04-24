class ProfilesController < ApplicationController
  include BirthDateTriplet

  def edit
    @user = Current.user
  end

  def update
    @user = Current.user
    attrs, dob_status = profile_attributes_with_dob

    if dob_status == :invalid
      @user.assign_attributes(attrs)
      @user.errors.add(:date_of_birth, :invalid_calendar)
      render :edit, status: :unprocessable_entity
    elsif @user.update(attrs)
      redirect_to edit_profile_path, notice: t("profiles.update.success")
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

    def profile_attributes_with_dob
      raw = params.require(:user).permit(
        :birth_year, :birth_month, :birth_day,
        :timezone, :allow_menu_freeform, :body_unit_system
      )
      dob = birth_date_from_triplet(raw[:birth_year], raw[:birth_month], raw[:birth_day])
      attrs = raw.except(:birth_year, :birth_month, :birth_day)
      case dob
      when :incomplete
        attrs[:date_of_birth] = nil
      when :invalid
        # omit date_of_birth so we do not persist an impossible day
      else
        attrs[:date_of_birth] = dob
      end
      [ attrs, dob ]
    end
end
