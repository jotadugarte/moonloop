# frozen_string_literal: true

module WeightLogs
  # Paginates ordered weight_logs for the history index (fixed page size).
  class HistoryPage
    PER_PAGE = 30

    Result = Struct.new(:records, :page, :total_pages, keyword_init: true)

    def self.call(scope:, page_param:)
      new(scope: scope, page_param: page_param).call
    end

    def initialize(scope:, page_param:)
      @scope = scope
      @page_param = page_param
    end

    def call
      total = @scope.count
      total_pages = total.zero? ? 1 : (total.to_f / PER_PAGE).ceil
      clamped = [ @page_param.to_i, 1 ].max
      page = [ clamped, total_pages ].min
      records = @scope.offset((page - 1) * PER_PAGE).limit(PER_PAGE)
      Result.new(records: records, page: page, total_pages: total_pages)
    end
  end
end
