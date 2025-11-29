# frozen_string_literal: true

class RenameCategoryToSpace < ActiveRecord::Migration[8.1]
  def change
    # Rename tables
    rename_table :categories, :spaces
    rename_table :category_moderators, :space_moderators
    rename_table :category_subscriptions, :space_subscriptions

    # Rename foreign key columns
    rename_column :questions, :category_id, :space_id
    rename_column :space_moderators, :category_id, :space_id
    rename_column :space_subscriptions, :category_id, :space_id

    # Rename indexes (Rails will handle most automatically, but let's be explicit for clarity)
    # The foreign key indexes will be renamed automatically by rename_column
  end
end
