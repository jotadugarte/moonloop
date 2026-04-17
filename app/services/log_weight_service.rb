class LogWeightService
  attr_reader :user, :weight_kg, :height_cm, :bmi_value, :logged_at

  def initialize(user:, weight_kg:, logged_at: Time.current)
    @user = user
    @logged_at = logged_at
    # Leveraging Value Objects (domain constraints) to fail fast on invalid arguments
    @weight_kg = WeightKg.new(value: weight_kg).value
    @height_cm = HeightCm.new(value: user.height_cm).value
    @bmi_value = BmiValue.compute(weight_kg: @weight_kg, height_cm: @height_cm).value
  end

  def call
    ActiveRecord::Base.transaction do
      log = user.weight_logs.create!(
        weight_kg: weight_kg,
        height_cm: height_cm,
        bmi: bmi_value,
        logged_at: logged_at
      )

      WeightLogs::ReconcileUserCurrentStats.call(user: user)

      log
    end
  end
end
