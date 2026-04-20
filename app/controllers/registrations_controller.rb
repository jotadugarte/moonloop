class RegistrationsController < ApplicationController
  skip_before_action :authenticate

  def new
    @user = User.new(body_unit_system: "metric")
    @reg_height_feet = nil
    @reg_height_inches = nil
  end

  def create
    @reg_height_feet = params.dig(:user, :height_feet)
    @reg_height_inches = params.dig(:user, :height_inches)
    @user = User.new(registration_user_attributes)

    if @user.save
      session_record = @user.sessions.create!
      cookies.signed.permanent[:session_token] = { value: session_record.id, httponly: true }

      send_email_verification
      redirect_to root_path, notice: t("registrations.create.signed_up")
    else
      render :new, status: :unprocessable_entity
    end
  end

  private
    def registration_user_attributes
      raw = params.require(:user).permit(
        :email, :password, :password_confirmation,
        :date_of_birth, :timezone, :body_unit_system,
        :height_cm, :height_feet, :height_inches
      )
      system = User::BODY_UNIT_SYSTEMS.include?(raw[:body_unit_system]) ? raw[:body_unit_system] : "metric"
      height_cm =
        if system == "imperial_us"
          BodyMetrics.ft_in_to_cm(raw[:height_feet].to_i, raw[:height_inches].to_i).round(0).to_i
        else
          raw[:height_cm].presence&.to_i
        end

      {
        email: raw[:email],
        password: raw[:password],
        password_confirmation: raw[:password_confirmation],
        date_of_birth: raw[:date_of_birth],
        timezone: raw[:timezone],
        body_unit_system: system,
        height_cm: height_cm
      }
    end

    def send_email_verification
      UserMailer.with(user: @user).email_verification.deliver_later
    end
end
