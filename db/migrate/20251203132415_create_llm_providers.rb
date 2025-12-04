# frozen_string_literal: true

class CreateLlmProviders < ActiveRecord::Migration[8.1]
  def change
    create_table :llm_providers do |t|
      t.string :name, null: false
      t.string :provider_type, null: false
      t.string :api_key
      t.string :api_endpoint
      t.string :model_name, null: false
      t.boolean :enabled, null: false, default: false
      t.boolean :is_default, null: false, default: false
      t.jsonb :settings, null: false, default: {}

      t.timestamps
    end

    add_index :llm_providers, :provider_type
    add_index :llm_providers, :enabled
    add_index :llm_providers, :is_default
    add_index :llm_providers, :name, unique: true
  end
end
