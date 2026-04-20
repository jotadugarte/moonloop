# frozen_string_literal: true

class CreateWebPushSubscriptions < ActiveRecord::Migration[8.1]
  def change
    create_table :web_push_subscriptions do |t|
      t.references :user, null: false, foreign_key: true
      t.string :endpoint, null: false
      t.string :p256dh, null: false
      t.string :auth, null: false
      t.timestamps
    end

    add_index :web_push_subscriptions,
              %i[user_id endpoint],
              unique: true,
              name: "index_web_push_subscriptions_uniqueness"
  end
end

