class CreateUsers < ActiveRecord::Migration[8.1]
  def change
    create_table :users do |t|
      t.string :email,           null: false, index: { unique: true }
      t.string :password_digest, null: false

      t.boolean :verified, null: false, default: false

      t.date :date_of_birth, null: false
      t.integer :height_cm, null: false
      t.string :timezone, null: false, default: ''
      t.decimal :current_weight_kg, precision: 5, scale: 2
      t.decimal :current_bmi, precision: 4, scale: 2

      t.timestamps
    end
  end
end
