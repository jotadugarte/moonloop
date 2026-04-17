class LogWeightService
  attr_reader :user, :weight_kg, :height_cm, :bmi_value

  def initialize(user:, weight_kg:)
    @user = user
    # Leveraging Value Objects (domain constraints) to fail fast on invalid arguments
    @weight_kg = WeightKg.new(value: weight_kg).value
    @height_cm = HeightCm.new(value: user.height_cm).value
    @bmi_value = BmiValue.compute(weight_kg: @weight_kg, height_cm: @height_cm).value
  end

  def call
    ActiveRecord::Base.transaction do
      # Create log snapshot
      log = user.weight_logs.create!(
        weight_kg: weight_kg,
        height_cm: height_cm,
        bmi: bmi_value,
        logged_at: Time.current
      )

      # Sink current values to User for faster reads
      user.update!(
        current_weight_kg: weight_kg,
        current_bmi: bmi_value
      )

      log
    end
  end
end
