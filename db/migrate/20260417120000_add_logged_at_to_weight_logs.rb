class AddLoggedAtToWeightLogs < ActiveRecord::Migration[8.1]
  def up
    add_column :weight_logs, :logged_at, :datetime
    execute "UPDATE weight_logs SET logged_at = created_at"
    change_column_null :weight_logs, :logged_at, false
    remove_index :weight_logs, column: [ :user_id, :created_at ]
    add_index :weight_logs, [ :user_id, :logged_at ]
  end

  def down
    remove_index :weight_logs, column: [ :user_id, :logged_at ]
    add_index :weight_logs, [ :user_id, :created_at ]
    remove_column :weight_logs, :logged_at
  end
end
