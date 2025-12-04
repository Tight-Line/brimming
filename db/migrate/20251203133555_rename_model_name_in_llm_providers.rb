# frozen_string_literal: true

class RenameModelNameInLlmProviders < ActiveRecord::Migration[8.1]
  def change
    rename_column :llm_providers, :model_name, :llm_model
  end
end
