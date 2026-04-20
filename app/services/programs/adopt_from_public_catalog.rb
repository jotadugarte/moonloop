# frozen_string_literal: true

module Programs
  class AdoptFromPublicCatalog
    class Error < StandardError
      attr_reader :key

      def initialize(key)
        @key = key
        super()
      end
    end

    def self.call(adopter:, source:, chosen_name:)
      raise Error.new(:not_public) unless source.publicly_shareable?
      raise Error.new(:cannot_adopt_own) if source.user_id == adopter.id
      if adopter.phase_programs.where(source_phase_program_id: source.id).exists?
        raise Error.new(:already_adopted)
      end

      name = chosen_name.to_s.strip
      raise Error.new(:name_blank) if name.blank?

      fp = ContentFingerprint.for_program(source)

      ApplicationRecord.transaction do
        menu_map = {}
        routine_map = {}

        source.phase_program_assignments.order(:start_week, :id).each do |seg|
          menu_base = "#{name} — #{seg.menu.name}"
          menu_map[seg.menu_id] ||= Menus::CopyMenuForAdopter.call(
            source_menu: seg.menu,
            adopter: adopter,
            base_name: menu_base
          )

          routine_base = "#{name} — #{seg.exercise_routine.name}"
          routine_map[seg.exercise_routine_id] ||= ExerciseRoutines::CopyRoutineForAdopter.call(
            source: seg.exercise_routine,
            adopter: adopter,
            base_name: routine_base
          )
        end

        copy = PhaseProgram.new(
          user: adopter,
          name: name,
          source_phase_program_id: source.id,
          source_sync_fingerprint: fp,
          adoption_catalog_origin_id: source.id,
          publicly_shareable: false
        )
        copy.save!

        source.phase_program_assignments.order(:start_week, :id).each do |seg|
          copy.phase_program_assignments.create!(
            menu_id: menu_map[seg.menu_id].id,
            exercise_routine_id: routine_map[seg.exercise_routine_id].id,
            start_week: seg.start_week,
            end_week: seg.end_week
          )
        end

        copy
      end
    end
  end
end
