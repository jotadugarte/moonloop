# frozen_string_literal: true

module RegistrationsHelper
  def registration_imperial_height_for_toggle?(user)
    user.body_unit_system == "imperial_us"
  end
end
