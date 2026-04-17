# frozen_string_literal: true

module WeightLogs
  class DestroyLog
    def self.call(weight_log:)
      ApplicationRecord.transaction do
        user = weight_log.user
        weight_log.destroy!
        ReconcileUserCurrentStats.call(user: user)
      end
    end
  end
end
