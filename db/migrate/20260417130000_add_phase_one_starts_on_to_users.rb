class AddPhaseOneStartsOnToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :phase_one_starts_on, :date
  end
end
