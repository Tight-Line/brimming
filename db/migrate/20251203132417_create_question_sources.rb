# frozen_string_literal: true

class CreateQuestionSources < ActiveRecord::Migration[8.1]
  def change
    create_table :question_sources do |t|
      t.references :question, null: false, foreign_key: true
      t.string :source_type, null: false
      t.bigint :source_id
      t.text :source_excerpt

      t.timestamps
    end

    add_index :question_sources, [ :source_type, :source_id ]
  end
end
