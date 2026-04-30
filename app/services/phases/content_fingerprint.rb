# frozen_string_literal: true

require "digest"
require "json"

module Phases
  class ContentFingerprint
    def self.for_phase(phase)
      menu_blocks = phase.phase_menu_blocks.includes(:menu).to_a.sort_by { |b| [ b.start_week, b.end_week, b.id || 0 ] }
      routine_blocks = phase.phase_routine_blocks.includes(:exercise_routine).to_a.sort_by do |b|
        [ b.start_week, b.end_week, b.id || 0 ]
      end

      payload = {
        weeks_total: phase.weeks_total,
        menu_blocks: menu_blocks.map { |b| [ b.start_week, b.end_week, Menus::ContentFingerprint.for_menu(b.menu) ] },
        routine_blocks: routine_blocks.map do |b|
          [ b.start_week, b.end_week, ExerciseRoutines::ContentFingerprint.for_routine(b.exercise_routine) ]
        end
      }

      Digest::SHA256.hexdigest(JSON.generate(payload))
    end
  end
end
