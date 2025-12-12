# frozen_string_literal: true

class CreateReaderProviders < ActiveRecord::Migration[8.1]
  def change
    create_table :reader_providers do |t|
      t.string :name, null: false
      t.string :provider_type, null: false
      t.string :api_key
      t.string :api_endpoint
      t.boolean :enabled, default: false, null: false
      t.jsonb :settings, default: {}, null: false

      t.timestamps
    end

    add_index :reader_providers, :name, unique: true
    add_index :reader_providers, :enabled
  end
end
