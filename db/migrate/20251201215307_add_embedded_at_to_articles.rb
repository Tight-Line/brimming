# frozen_string_literal: true

class AddEmbeddedAtToArticles < ActiveRecord::Migration[8.1]
  def change
    add_column :articles, :embedded_at, :datetime
    add_index :articles, :embedded_at
  end
end
