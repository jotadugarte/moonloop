# frozen_string_literal: true

class CreatePhaseAssignments < ActiveRecord::Migration[8.1]
  def change
    create_table :phase_assignments do |t|
      t.references :user, null: false, foreign_key: true
      t.references :menu, null: false, foreign_key: true
      t.integer :start_week, null: false
      t.integer :end_week, null: false

      t.timestamps
    end

    add_index :phase_assignments, %i[user_id start_week end_week], name: "index_phase_assignments_on_user_and_range"
  end
end
