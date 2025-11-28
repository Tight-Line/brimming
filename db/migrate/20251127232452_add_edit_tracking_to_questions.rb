# frozen_string_literal: true

class AddEditTrackingToQuestions < ActiveRecord::Migration[8.1]
  def change
    add_column :questions, :edited_at, :datetime
    add_reference :questions, :last_editor, foreign_key: { to_table: :users }
  end
end
