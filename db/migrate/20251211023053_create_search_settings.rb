class CreateSearchSettings < ActiveRecord::Migration[8.1]
  def change
    create_table :search_settings do |t|
      t.string :key, null: false
      t.text :value, null: false
      t.string :description

      t.timestamps
    end
    add_index :search_settings, :key, unique: true
  end
end
