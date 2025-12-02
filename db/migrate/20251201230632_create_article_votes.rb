class CreateArticleVotes < ActiveRecord::Migration[8.1]
  def change
    create_table :article_votes do |t|
      t.references :user, null: false, foreign_key: true
      t.references :article, null: false, foreign_key: true
      t.integer :value, null: false

      t.timestamps
    end

    add_index :article_votes, [ :user_id, :article_id ], unique: true
  end
end
