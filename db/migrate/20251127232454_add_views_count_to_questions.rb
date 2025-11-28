# frozen_string_literal: true

class AddViewsCountToQuestions < ActiveRecord::Migration[8.1]
  def change
    add_column :questions, :views_count, :integer, null: false, default: 0
    add_index :questions, :views_count
  end
end
