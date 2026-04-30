# frozen_string_literal: true

class CreatePhases < ActiveRecord::Migration[8.1]
  def change
    create_table :phases do |t|
      t.bigint :user_id, null: false
      t.string :name, null: false
      t.string :name_normalized, null: false
      t.integer :weeks_total, null: false

      t.boolean :publicly_shareable, null: false, default: false
      t.bigint :source_phase_id
      t.string :source_sync_fingerprint
      t.bigint :adoption_catalog_origin_id

      t.integer :public_catalog_adoptions_count, null: false, default: 0
      t.integer :public_catalog_distinct_adopters_count, null: false, default: 0

      t.timestamps
    end

    add_foreign_key :phases, :users
    add_foreign_key :phases, :phases, column: :source_phase_id

    add_index :phases, :user_id
    add_index :phases, :source_phase_id
    add_index :phases, [ :user_id, :name_normalized ],
      unique: true,
      name: "index_phases_on_user_and_name_normalized"
    add_index :phases, [ :user_id, :source_phase_id ],
      unique: true,
      where: "source_phase_id IS NOT NULL",
      name: "index_phases_adoption_unique_per_user_and_source"

    add_check_constraint :phases, "weeks_total >= 1", name: "phases_weeks_total_gte_one"
  end
end
