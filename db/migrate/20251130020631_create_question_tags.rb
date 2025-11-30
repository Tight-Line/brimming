# frozen_string_literal: true

class CreateQuestionTags < ActiveRecord::Migration[8.1]
  def change
    create_table :question_tags do |t|
      t.references :question, null: false, foreign_key: true
      t.references :tag, null: false, foreign_key: true

      t.timestamps
    end

    # Unique constraint: a question can only have each tag once
    add_index :question_tags, [ :question_id, :tag_id ], unique: true
  end
end
