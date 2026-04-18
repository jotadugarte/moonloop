# frozen_string_literal: true

module WeightLogs
  # Sets User#current_weight_kg and User#current_bmi from the latest WeightLog by
  # logged_at (tie-break id descending), or clears both when no logs exist.
  class ReconcileUserCurrentStats
    def self.call(user:)
      new(user: user).call
    end

    def initialize(user:)
      @user = user
    end

    def call
      latest = user.weight_logs.order(logged_at: :desc, id: :desc).first
      if latest
        user.update!(
          current_weight_kg: latest.weight_kg,
          current_bmi: latest.bmi
        )
      else
        user.update!(
          current_weight_kg: nil,
          current_bmi: nil
        )
      end
    end

    private

    attr_reader :user
  end
end
