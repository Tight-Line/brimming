# frozen_string_literal: true

class CreateQuestionVotes < ActiveRecord::Migration[8.1]
  def change
    create_table :question_votes do |t|
      t.references :user, null: false, foreign_key: true
      t.references :question, null: false, foreign_key: true
      t.integer :value, null: false

      t.timestamps
    end

    add_index :question_votes, [ :user_id, :question_id ], unique: true

    # Add vote_score to questions for caching
    add_column :questions, :vote_score, :integer, null: false, default: 0
    add_index :questions, :vote_score
  end
end
