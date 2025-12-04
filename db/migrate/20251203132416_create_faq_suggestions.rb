# frozen_string_literal: true

class CreateFaqSuggestions < ActiveRecord::Migration[8.1]
  def change
    create_table :faq_suggestions do |t|
      t.references :space, null: false, foreign_key: true
      t.references :created_by, null: false, foreign_key: { to_table: :users }
      t.uuid :batch_id, null: false
      t.string :source_type, null: false
      t.text :source_context
      t.string :question_text, null: false
      t.text :answer_text, null: false
      t.string :status, null: false, default: "pending"

      t.timestamps
    end

    add_index :faq_suggestions, :batch_id
    add_index :faq_suggestions, [ :space_id, :status ]
    add_index :faq_suggestions, :created_at
    add_index :faq_suggestions, :status
  end
end
