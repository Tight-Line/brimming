# frozen_string_literal: true

class CreateVotes < ActiveRecord::Migration[8.1]
  def change
    create_table :votes do |t|
      t.references :user, null: false, foreign_key: true
      t.references :answer, null: false, foreign_key: true
      t.integer :value, null: false

      t.timestamps
    end

    # Each user can only vote once per answer
    add_index :votes, [ :user_id, :answer_id ], unique: true
  end
end
