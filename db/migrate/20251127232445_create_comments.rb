# frozen_string_literal: true

class CreateComments < ActiveRecord::Migration[8.1]
  def change
    create_table :comments do |t|
      t.text :body, null: false
      t.references :user, null: false, foreign_key: true
      t.references :commentable, polymorphic: true, null: false
      t.references :parent_comment, foreign_key: { to_table: :comments }
      t.integer :vote_score, null: false, default: 0

      t.timestamps
    end

    add_index :comments, [ :commentable_type, :commentable_id, :created_at ],
              name: "index_comments_on_commentable_and_created_at"
  end
end
