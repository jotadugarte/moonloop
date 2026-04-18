# frozen_string_literal: true

module WeightLogs
  # REQ-RPT-003: All weigh-ins for charting — one relation, indexed (user_id, logged_at),
  # ascending time, minimal columns. Does not use HistoryPage pagination.
  class ChartSeries
    CHART_COLUMNS = %i[id logged_at weight_kg bmi].freeze

    def self.call(user:)
      new(user: user).call
    end

    def initialize(user:)
      @user = user
    end

    def call
      @user.weight_logs
        .order(logged_at: :asc, id: :asc)
        .select(*CHART_COLUMNS)
    end
  end
end
