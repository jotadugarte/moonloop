BmiValue = Data.define(:value) do
  def self.compute(weight_kg:, height_cm:)
    bmi = BigDecimal(weight_kg.to_s) / (BigDecimal(height_cm.to_s) / 100) ** 2
    new(value: bmi.round(2))
  end
end
