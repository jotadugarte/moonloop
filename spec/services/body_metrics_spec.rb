# frozen_string_literal: true

require "rails_helper"

RSpec.describe BodyMetrics do
  describe "constants" do
    # [REQ-PROF-003, REQ-WGT-004]
    it "exposes explicit BigDecimal conversion factors (lb↔kg and cm↔in)" do
      expect(described_class::LB_PER_KG).to be_a(BigDecimal)
      expect(described_class::KG_PER_LB).to be_a(BigDecimal)
      expect(described_class::CM_PER_INCH).to eq(BigDecimal("2.54"))
      expect(described_class::INCHES_PER_FOOT).to eq(12)
    end
  end

  describe ".kg_to_lb_for_display" do
    # [REQ-PROF-003, REQ-WGT-004]
    it "formats kg to lb with exactly one decimal (chart-style canonical weight)" do
      expect(described_class.kg_to_lb_for_display(BigDecimal("70.0"))).to eq(BigDecimal("154.3"))
      expect(described_class.kg_to_lb_for_display(BigDecimal("70.5"))).to eq(BigDecimal("155.4"))
    end
  end

  describe ".lb_to_kg" do
    # [REQ-PROF-003, REQ-WGT-004]
    it "converts lb to canonical kg using BigDecimal without using display-rounded intermediates" do
      kg = described_class.lb_to_kg(BigDecimal("154.3236"))
      expect(kg).to be_within(BigDecimal("0.0001")).of(BigDecimal("70"))
    end
  end

  describe ".cm_to_ft_in" do
    # [REQ-PROF-003, REQ-WGT-004]
    it "returns integer feet and integer inches 0–11 (factory / chart default height)" do
      expect(described_class.cm_to_ft_in(180)).to eq([ 5, 11 ])
    end

    # [REQ-PROF-003, REQ-WGT-004]
    it "rolls 12 inches up to the next foot" do
      expect(described_class.cm_to_ft_in(
        described_class.ft_in_to_cm(5, 12)
      )).to eq([ 6, 0 ])
    end
  end

  describe ".ft_in_to_cm" do
    # [REQ-PROF-003, REQ-WGT-004]
    it "converts ft + integer inches to canonical cm (69 in × 2.54 cm/in)" do
      expect(described_class.ft_in_to_cm(5, 9)).to eq(BigDecimal("175.26"))
    end
  end

  describe "BMI-oriented round-trip safety" do
    # [REQ-PROF-003, REQ-WGT-004]
    it "keeps BMI stable when using only canonical kg/cm (display rounding is not fed back into BMI)" do
      weight_kg = BigDecimal("71.0")
      height_cm = BigDecimal("180")
      bmi = weight_kg / ((height_cm / BigDecimal("100")) ** 2)

      display_lb = described_class.kg_to_lb_for_display(weight_kg)
      round_trip_kg = described_class.lb_to_kg(display_lb)

      bmi_from_round_trip = round_trip_kg / ((height_cm / BigDecimal("100")) ** 2)
      expect(bmi_from_round_trip).to be_within(BigDecimal("0.01")).of(bmi)
    end
  end
end
