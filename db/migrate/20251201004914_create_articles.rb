# frozen_string_literal: true

class CreateArticles < ActiveRecord::Migration[8.1]
  def change
    create_table :articles do |t|
      # Core content
      t.string :title, null: false
      t.text :body
      t.string :content_type, null: false, default: "markdown"
      t.text :context # Publisher-provided context for search/RAG

      # Author/editor tracking
      t.references :user, null: false, foreign_key: true
      t.references :last_editor, foreign_key: { to_table: :users }
      t.datetime :edited_at

      # URL-friendly identifier
      t.string :slug, null: false

      # Soft delete
      t.datetime :deleted_at

      t.timestamps
    end

    add_index :articles, :slug, unique: true
    add_index :articles, :deleted_at
    add_index :articles, :content_type
  end
end
