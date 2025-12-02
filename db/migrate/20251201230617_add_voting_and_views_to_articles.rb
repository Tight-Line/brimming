class AddVotingAndViewsToArticles < ActiveRecord::Migration[8.1]
  def change
    add_column :articles, :vote_score, :integer, default: 0, null: false
    add_column :articles, :views_count, :integer, default: 0, null: false

    add_index :articles, :vote_score
    add_index :articles, :views_count
  end
end
