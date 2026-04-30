# frozen_string_literal: true

module Plans
  class BuildFromPhases
    def self.call(user:, name:, phases:)
      new(user: user, name: name, phases: phases).call
    end

    def initialize(user:, name:, phases:)
      @user = user
      @name = name.to_s.strip
      @phases = Array(phases)
    end

    def call
      raise ArgumentError, "name blank" if @name.blank?
      raise ArgumentError, "phases empty" if @phases.empty?

      ApplicationRecord.transaction do
        plan = Plan.create!(user: @user, name: @name, publicly_shareable: false)
        build_segments!(plan: plan)
        plan
      end
    end

    private

    def build_segments!(plan:)
      cursor_week = 1
      @phases.each do |phase|
        raise ArgumentError, "phase wrong owner" if phase.user_id != @user.id
        raise ArgumentError, "phase invalid" unless phase.valid?

        menu_blocks = phase.phase_menu_blocks.order(:start_week, :id)
        routine_blocks = phase.phase_routine_blocks.order(:start_week, :id)
        raise ArgumentError, "phase blocks missing" if menu_blocks.empty? || routine_blocks.empty?

        menu_map = copy_menus(menu_blocks)
        routine_map = copy_routines(routine_blocks)

        menu_blocks.zip(routine_blocks).each do |menu_block, routine_block|
          raise ArgumentError, "phase block mismatch" if routine_block.nil?
          if menu_block.start_week != routine_block.start_week || menu_block.end_week != routine_block.end_week
            raise ArgumentError, "phase block mismatch"
          end

          span = menu_block.end_week - menu_block.start_week
          start_week = cursor_week
          end_week = cursor_week + span
          plan.plan_assignments.create!(
            menu_id: menu_map.fetch(menu_block.menu_id).id,
            exercise_routine_id: routine_map.fetch(routine_block.exercise_routine_id).id,
            start_week: start_week,
            end_week: end_week
          )
          cursor_week = end_week + 1
        end
      end
    end

    def copy_menus(menu_blocks)
      menu_blocks.each_with_object({}) do |block, acc|
        acc[block.menu_id] ||= Menus::CopyMenuForAdopter.call(
          source_menu: block.menu,
          adopter: @user,
          base_name: "#{@name} — #{block.menu.name}"
        )
      end
    end

    def copy_routines(routine_blocks)
      routine_blocks.each_with_object({}) do |block, acc|
        acc[block.exercise_routine_id] ||= ExerciseRoutines::CopyRoutineForAdopter.call(
          source: block.exercise_routine,
          adopter: @user,
          base_name: "#{@name} — #{block.exercise_routine.name}"
        )
      end
    end
  end
end
