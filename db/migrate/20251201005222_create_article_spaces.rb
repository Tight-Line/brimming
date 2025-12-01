# frozen_string_literal: true

class CreateArticleSpaces < ActiveRecord::Migration[8.1]
  def change
    create_table :article_spaces do |t|
      t.references :article, null: false, foreign_key: true
      t.references :space, null: false, foreign_key: true

      t.timestamps
    end

    # Each article can only be in a space once
    add_index :article_spaces, [ :article_id, :space_id ], unique: true
  end
end
