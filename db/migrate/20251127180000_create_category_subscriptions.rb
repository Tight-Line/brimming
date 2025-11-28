# frozen_string_literal: true

class CreateCategorySubscriptions < ActiveRecord::Migration[8.1]
  def change
    create_table :category_subscriptions do |t|
      t.references :user, null: false, foreign_key: true
      t.references :category, null: false, foreign_key: true

      t.timestamps
    end

    add_index :category_subscriptions, [ :user_id, :category_id ], unique: true
  end
end
