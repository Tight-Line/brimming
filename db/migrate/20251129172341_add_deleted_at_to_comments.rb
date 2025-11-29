class AddDeletedAtToComments < ActiveRecord::Migration[8.1]
  def change
    add_column :comments, :deleted_at, :datetime
  end
end
