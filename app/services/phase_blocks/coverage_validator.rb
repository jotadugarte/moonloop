# frozen_string_literal: true

module PhaseBlocks
  class CoverageValidator
    def self.call(phase:)
      new(phase: phase).call
    end

    def initialize(phase:)
      @phase = phase
    end

    def call
      return if @phase.phase_menu_blocks.empty? && @phase.phase_routine_blocks.empty?

      add_menu_coverage_errors
      add_routine_overlap_errors
      add_parity_errors
    end

    private

    def add_menu_coverage_errors
      menu_weeks = covered_weeks(@phase.phase_menu_blocks)
      expected = expected_weeks
      @phase.errors.add(:base, :menu_blocks_incomplete_coverage) unless menu_weeks == expected
    end

    def add_routine_overlap_errors
      rows = @phase.phase_routine_blocks
      @phase.errors.add(:base, :routine_blocks_overlap) if overlaps?(rows)
    end

    def add_parity_errors
      menu_weeks = covered_weeks(@phase.phase_menu_blocks)
      routine_weeks = covered_weeks(@phase.phase_routine_blocks)
      missing_routine = (menu_weeks - routine_weeks).any?
      @phase.errors.add(:base, :week_missing_routine) if missing_routine
    end

    def expected_weeks
      (1..@phase.weeks_total).to_a
    end

    def covered_weeks(rows)
      rows.flat_map { |r| (r.start_week..r.end_week).to_a }.uniq.sort
    end

    def overlaps?(rows)
      sorted = rows.sort_by { |r| [ r.start_week.to_i, r.end_week.to_i ] }
      sorted.each_cons(2).any? { |a, b| a.end_week.to_i >= b.start_week.to_i }
    end
  end
end
