# frozen_string_literal: true

require "rails_helper"

RSpec.describe HabitReminderMailer do
  # [REQ-HAB-013]
  it "renders a localized subject and includes the habit name" do
    user = create(:user, email: "test@example.com")
    habit = create(:user_habit, user: user, name: "Agua")

    I18n.with_locale(:es) do
      mail = described_class.notify(user: user, user_habit: habit)
      expect(mail.subject).to include("Agua")
      expect(mail.to).to eq([ "test@example.com" ])
      expect(mail.body.encoded).to include("Agua")
    end
  end
end
