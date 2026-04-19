# frozen_string_literal: true

class CreatePhasePrograms < ActiveRecord::Migration[8.1]
  def change
    create_table :phase_programs do |t|
      t.integer :user_id, null: false
      t.string :name, null: false
      t.string :name_normalized, null: false
      t.boolean :publicly_shareable, null: false, default: false
      t.integer :source_phase_program_id
      t.string :source_sync_fingerprint
      t.integer :adoption_catalog_origin_id

      t.timestamps
    end

    add_foreign_key :phase_programs, :users
    add_foreign_key :phase_programs, :phase_programs, column: :source_phase_program_id

    add_index :phase_programs, :user_id
    add_index :phase_programs, :source_phase_program_id
    add_index :phase_programs, [ :user_id, :name_normalized ],
      unique: true,
      name: "index_phase_programs_on_user_and_name_normalized"
    add_index :phase_programs, [ :user_id, :source_phase_program_id ],
      unique: true,
      where: "source_phase_program_id IS NOT NULL",
      name: "index_phase_programs_adoption_unique_per_user_and_source"
  end
end
