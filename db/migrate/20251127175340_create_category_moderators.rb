# frozen_string_literal: true

class CreateCategoryModerators < ActiveRecord::Migration[8.1]
  def change
    create_table :category_moderators do |t|
      t.references :category, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end

    # Each user can only be a moderator of a category once
    add_index :category_moderators, [ :category_id, :user_id ], unique: true
  end
end
