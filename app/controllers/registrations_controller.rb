class RegistrationsController < ApplicationController
  skip_before_action :authenticate

  def new
    @user = User.new
  end

  def create
    @user = User.new(user_params)

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
    def user_params
      params.require(:user).permit(:email, :password, :password_confirmation, :date_of_birth, :height_cm, :timezone)
    end

    def send_email_verification
      UserMailer.with(user: @user).email_verification.deliver_later
    end
end
