class ProfilesController < ApplicationController
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
      raw = profile_permitted_params
      dob = BirthDateTriplet.parse(raw[:birth_year], raw[:birth_month], raw[:birth_day])
      attrs = profile_base_attrs(raw)
      apply_profile_date_of_birth(attrs, dob)
      [ attrs, dob ]
    end

    def profile_permitted_params
      params.require(:user).permit(
        :birth_year, :birth_month, :birth_day,
        :timezone, :allow_menu_freeform, :body_unit_system
      )
    end

    def profile_base_attrs(raw)
      raw.except(:birth_year, :birth_month, :birth_day)
    end

    def apply_profile_date_of_birth(attrs, dob)
      case dob
      when :incomplete
        attrs[:date_of_birth] = nil
      when :invalid
        nil
      else
        attrs[:date_of_birth] = dob
      end
    end
end
