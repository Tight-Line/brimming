# frozen_string_literal: true

# Global search and RAG settings stored as key-value pairs.
#
# Usage:
#   SearchSetting.rag_chunk_limit           # => 10 (default)
#   SearchSetting.rag_chunk_limit = 15      # update the setting
#   SearchSetting.get("custom_key")         # generic getter
#   SearchSetting.set("custom_key", "val")  # generic setter
#
class SearchSetting < ApplicationRecord
  # Path to the default persona prompt file
  DEFAULT_PERSONA_PATH = Rails.root.join("config/prompts/qa_wizard_persona.md")

  # Known setting keys and their defaults (text defaults loaded from files)
  DEFAULTS = {
    "rag_chunk_limit" => 10,
    "similar_questions_limit" => 3
  }.freeze

  validates :key, presence: true, uniqueness: true
  validates :value, presence: true

  # Generic getter - returns default if not set
  def self.get(key)
    setting = find_by(key: key)
    setting&.value || DEFAULTS[key.to_s]
  end

  # Generic setter - creates or updates
  def self.set(key, value, description: nil)
    setting = find_or_initialize_by(key: key)
    setting.value = value.to_s
    setting.description = description if description.present?
    setting.save!
    setting
  end

  # Typed accessor for rag_chunk_limit
  def self.rag_chunk_limit
    get("rag_chunk_limit").to_i
  end

  def self.rag_chunk_limit=(value)
    set("rag_chunk_limit", value.to_i, description: "Maximum number of chunks to retrieve for RAG queries")
  end

  # Typed accessor for similar_questions_limit
  def self.similar_questions_limit
    get("similar_questions_limit").to_i
  end

  def self.similar_questions_limit=(value)
    set("similar_questions_limit", value.to_i, description: "Number of similar existing questions to show in Q&A Wizard")
  end

  # Typed accessor for qa_wizard_persona (text prompt)
  # Returns the stored persona or the default from file
  def self.qa_wizard_persona
    setting = find_by(key: "qa_wizard_persona")
    setting&.value || default_persona
  end

  def self.qa_wizard_persona=(value)
    set("qa_wizard_persona", value.to_s, description: "System-wide persona prompt for Q&A Wizard content generation")
  end

  # Load default persona from file
  def self.default_persona
    @default_persona ||= File.read(DEFAULT_PERSONA_PATH)
  end
end
