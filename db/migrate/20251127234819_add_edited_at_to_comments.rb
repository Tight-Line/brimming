class AddEditedAtToComments < ActiveRecord::Migration[8.1]
  def change
    add_column :comments, :edited_at, :datetime
    add_reference :comments, :last_editor, foreign_key: { to_table: :users }
  end
end
