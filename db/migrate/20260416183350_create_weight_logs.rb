class CreateWeightLogs < ActiveRecord::Migration[8.1]
  def change
    create_table :weight_logs do |t|
      t.references :user, null: false, foreign_key: true
      t.decimal :weight_kg, precision: 5, scale: 2, null: false
      t.integer :height_cm, null: false
      t.decimal :bmi, precision: 4, scale: 2, null: false

      t.timestamps
    end

    add_index :weight_logs, [:user_id, :created_at]
  end
end
