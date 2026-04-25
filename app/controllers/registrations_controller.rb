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

    attrs, dob_status, weight_status = registration_user_attributes_tuple
    @user = User.new(attrs)

    if dob_status == :invalid
      @user.errors.add(:date_of_birth, :invalid_calendar)
      render :new, status: :unprocessable_content
    elsif weight_status == :invalid
      @user.errors.add(:current_weight_kg, :invalid)
      render :new, status: :unprocessable_content
    elsif @user.save
      session_record = @user.sessions.create!
      cookies.signed.permanent[:session_token] = { value: session_record.id, httponly: true }

      send_email_verification
      redirect_to root_path, notice: t("registrations.create.signed_up")
    else
      render :new, status: :unprocessable_content
    end
  end

  private

    def registration_user_attributes_tuple
      raw = registration_permitted_params
      system = registration_body_unit_system(raw[:body_unit_system])
      height_cm = registration_height_cm(raw, system)
      weight_kg, weight_status = registration_weight_kg_tuple(raw, system)
      current_bmi = registration_current_bmi(weight_kg, height_cm)
      dob = BirthDateTriplet.parse(raw[:birth_year], raw[:birth_month], raw[:birth_day])
      [ build_registration_attrs(raw, dob, system, height_cm, weight_kg, current_bmi), dob, weight_status ]
    end

    def registration_permitted_params
      params.require(:user).permit(
        :email, :password, :password_confirmation,
        :birth_year, :birth_month, :birth_day,
        :timezone, :body_unit_system,
        :height_cm, :height_feet, :height_inches,
        :weight_kg, :weight_lb
      )
    end

    def registration_body_unit_system(value)
      User::BODY_UNIT_SYSTEMS.include?(value) ? value : "metric"
    end

    def registration_height_cm(raw, system)
      if system == "imperial_us"
        BodyMetrics.ft_in_to_cm(raw[:height_feet].to_i, raw[:height_inches].to_i).round(0).to_i
      else
        raw[:height_cm].presence&.to_i
      end
    end

    def registration_weight_kg_tuple(raw, system)
      raw_value = system == "metric" ? raw[:weight_kg].presence : raw[:weight_lb].presence
      return [ nil, :blank ] if raw_value.nil?

      weight_kg = weight_kg_from_units(raw_value, system)
      [ WeightKg.new(value: weight_kg).value, :ok ]
    rescue ArgumentError => e
      return [ nil, :invalid ] if WeightKg.invalid_argument_error?(e)

      raise
    end

    def weight_kg_from_units(raw_value, system)
      return BigDecimal(raw_value.to_s) if system == "metric"

      BodyMetrics.lb_to_kg(raw_value).round(2)
    end

    def registration_current_bmi(weight_kg, height_cm)
      return nil if weight_kg.nil? || height_cm.nil?

      BmiValue.compute(weight_kg: weight_kg, height_cm: height_cm).value
    end

    def build_registration_attrs(raw, dob, system, height_cm, weight_kg, current_bmi)
      {
        email: raw[:email],
        password: raw[:password],
        password_confirmation: raw[:password_confirmation],
        date_of_birth: dob.is_a?(Date) ? dob : nil,
        timezone: raw[:timezone],
        body_unit_system: system,
        height_cm: height_cm,
        current_weight_kg: weight_kg,
        current_bmi: current_bmi
      }
    end

    def send_email_verification
      UserMailer.with(user: @user).email_verification.deliver_later
    end
end
