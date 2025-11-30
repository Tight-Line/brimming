# frozen_string_literal: true

class CreateEmbeddingProviders < ActiveRecord::Migration[8.1]
  def change
    create_table :embedding_providers do |t|
      t.string :name, null: false
      t.string :provider_type, null: false
      t.string :api_key
      t.string :api_endpoint
      t.string :embedding_model, null: false
      t.integer :dimensions, null: false
      t.boolean :enabled, null: false, default: false
      t.jsonb :settings, null: false, default: {}

      t.timestamps
    end

    add_index :embedding_providers, :provider_type
    add_index :embedding_providers, :enabled
  end
end
