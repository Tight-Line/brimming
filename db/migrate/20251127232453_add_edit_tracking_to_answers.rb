# frozen_string_literal: true

class AddEditTrackingToAnswers < ActiveRecord::Migration[8.1]
  def change
    add_column :answers, :edited_at, :datetime
    add_reference :answers, :last_editor, foreign_key: { to_table: :users }
  end
end
