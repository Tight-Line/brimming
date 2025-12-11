class CreateAnswerSources < ActiveRecord::Migration[8.1]
  def change
    create_table :answer_sources do |t|
      t.references :answer, null: false, foreign_key: true
      t.string :source_type, null: false
      t.integer :source_id
      t.string :source_title
      t.text :source_excerpt, null: false
      t.integer :citation_number

      t.timestamps
    end

    add_index :answer_sources, [ :answer_id, :citation_number ], unique: true
  end
end
