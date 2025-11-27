# frozen_string_literal: true

class CreateAnswers < ActiveRecord::Migration[8.1]
  def change
    create_table :answers do |t|
      t.text :body, null: false
      t.references :user, null: false, foreign_key: true
      t.references :question, null: false, foreign_key: true
      t.boolean :is_correct, null: false, default: false
      t.integer :vote_score, null: false, default: 0

      t.timestamps
    end

    add_index :answers, [ :question_id, :vote_score ]
    add_index :answers, [ :question_id, :is_correct ]
    add_index :answers, :vote_score
  end
end
