# frozen_string_literal: true

# Pure conversion helpers for canonical kg/cm ↔ US customary display (lb, ft/in).
# [REQ-PROF-003, REQ-WGT-004]
module BodyMetrics
  ROUND_DISPLAY = BigDecimal::ROUND_HALF_UP

  # 1 lb = 0.45359237 kg (international avoirdupois definition).
  KG_PER_LB = BigDecimal("0.45359237")
  LB_PER_KG = BigDecimal("1") / KG_PER_LB
  CM_PER_INCH = BigDecimal("2.54")
  INCHES_PER_FOOT = 12

  class << self
    def kg_to_lb_for_display(kg)
      k = BigDecimal(kg.to_s)
      raise ArgumentError, "kg must be finite" unless k.finite?

      raw_lb = k * LB_PER_KG
      rounded = raw_lb.round(1, ROUND_DISPLAY)
      raise ArgumentError, "display lb must be finite" unless rounded.finite?

      rounded
    end

    def lb_to_kg(lb)
      pounds = BigDecimal(lb.to_s)
      raise ArgumentError, "lb must be finite" unless pounds.finite?

      kg = pounds * KG_PER_LB
      raise ArgumentError, "kg must be finite" unless kg.finite?

      kg
    end

    def cm_to_ft_in(cm)
      centimeters = BigDecimal(cm.to_s)
      raise ArgumentError, "cm must be finite" unless centimeters.finite?

      total_inches = (centimeters / CM_PER_INCH).round(0, ROUND_DISPLAY)
      feet, inches = total_inches.divmod(INCHES_PER_FOOT)
      [ feet.to_i, inches.to_i ]
    end

    def ft_in_to_cm(feet, inches)
      f = Integer(feet)
      i = Integer(inches)
      total = (f * INCHES_PER_FOOT) + i
      cm = BigDecimal(total.to_s) * CM_PER_INCH
      raise ArgumentError, "cm must be finite" unless cm.finite?

      cm
    end
  end
end
