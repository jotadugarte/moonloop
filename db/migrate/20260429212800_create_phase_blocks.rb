# frozen_string_literal: true

class CreatePhaseBlocks < ActiveRecord::Migration[8.1]
  def change
    create_table :phase_menu_blocks do |t|
      t.bigint :phase_id, null: false
      t.bigint :menu_id, null: false
      t.integer :start_week, null: false
      t.integer :end_week, null: false
      t.timestamps
    end

    create_table :phase_routine_blocks do |t|
      t.bigint :phase_id, null: false
      t.bigint :exercise_routine_id, null: false
      t.integer :start_week, null: false
      t.integer :end_week, null: false
      t.timestamps
    end

    add_foreign_key :phase_menu_blocks, :phases
    add_foreign_key :phase_menu_blocks, :menus
    add_foreign_key :phase_routine_blocks, :phases
    add_foreign_key :phase_routine_blocks, :exercise_routines

    add_index :phase_menu_blocks, :phase_id
    add_index :phase_menu_blocks, [ :phase_id, :start_week, :end_week ], name: "index_phase_menu_blocks_on_phase_and_range"
    add_index :phase_routine_blocks, :phase_id
    add_index :phase_routine_blocks, [ :phase_id, :start_week, :end_week ], name: "index_phase_routine_blocks_on_phase_and_range"

    add_check_constraint :phase_menu_blocks, "start_week >= 1", name: "phase_menu_blocks_start_week_gte_one"
    add_check_constraint :phase_menu_blocks, "end_week >= start_week", name: "phase_menu_blocks_end_gte_start"
    add_check_constraint :phase_routine_blocks, "start_week >= 1", name: "phase_routine_blocks_start_week_gte_one"
    add_check_constraint :phase_routine_blocks, "end_week >= start_week", name: "phase_routine_blocks_end_gte_start"
  end
end

