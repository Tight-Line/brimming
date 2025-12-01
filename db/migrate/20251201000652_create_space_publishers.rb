class CreateSpacePublishers < ActiveRecord::Migration[8.1]
  def change
    create_table :space_publishers do |t|
      t.references :user, null: false, foreign_key: true
      t.references :space, null: false, foreign_key: true

      t.timestamps
    end

    add_index :space_publishers, [ :user_id, :space_id ], unique: true
  end
end
