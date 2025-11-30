# frozen_string_literal: true

class CreateTags < ActiveRecord::Migration[8.1]
  def change
    create_table :tags do |t|
      t.references :space, null: false, foreign_key: true
      t.string :name, null: false
      t.string :slug, null: false
      t.text :description
      t.integer :questions_count, null: false, default: 0

      t.timestamps
    end

    # Unique constraint: tag name must be unique within a space
    add_index :tags, [ :space_id, :name ], unique: true
    add_index :tags, [ :space_id, :slug ], unique: true
    add_index :tags, [ :space_id, :questions_count ]
  end
end
