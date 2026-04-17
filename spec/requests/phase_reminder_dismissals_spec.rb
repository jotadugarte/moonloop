# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Phase reminder dismiss-for-today", type: :request do
  let(:user) { create(:user, password: "Password123!", timezone: "Europe/Madrid") }

  before do
    post sign_in_path, params: { email: user.email, password: "Password123!" }
  end

  # [REQ-MENU-004]
  it "persists the user local calendar day when dismissing" do
    madrid = ActiveSupport::TimeZone["Europe/Madrid"].local(2026, 5, 10, 8, 0, 0)
    travel_to(madrid) do
      post dismiss_reminder_phase_path

      expect(response).to redirect_to(phase_path)
      expect(flash[:notice]).to eq(I18n.t("phases.flash.reminder_dismissed"))
      expect(user.reload.phase_reminder_dismissed_on).to eq(Date.new(2026, 5, 10))
    end
  end
end
