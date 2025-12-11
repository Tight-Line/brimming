# frozen_string_literal: true

# Service for building Q&A Wizard prompts with variable interpolation
#
# The prompt is composed of two parts:
# 1. Persona (editable): System-wide default from SearchSetting, overridable per-space
# 2. Instructions (fixed): RAG context and response format, always appended
#
# This ensures custom prompts can't break the required JSON response format.
#
# Usage:
#   service = QaWizardPromptService.new(space)
#   prompt = service.build_content_prompt(
#     title: "How do I reset my password?",
#     chunks: [chunk1, chunk2]
#   )
#
class QaWizardPromptService
  # Fixed instructions file - always appended to persona
  INSTRUCTIONS_PATH = Rails.root.join("config/prompts/qa_wizard_instructions.md")

  # Supported variables in persona prompts (instructions use RAG_CONTEXT internally)
  PERSONA_VARIABLES = %w[SPACE_NAME SPACE_DESCRIPTION].freeze

  attr_reader :space

  def initialize(space)
    @space = space
  end

  # Build the prompt for generating Q&A content
  # @param title [String] The question title
  # @param chunks [Array<Chunk>] Relevant context chunks from KB
  # @return [String] The interpolated prompt
  def build_content_prompt(title:, chunks:)
    persona = effective_persona
    instructions = instructions_template
    context = build_rag_context(chunks)

    # Interpolate persona variables
    persona_variables = {
      "SPACE_NAME" => space.name,
      "SPACE_DESCRIPTION" => space_description_section
    }
    interpolated_persona = interpolate(persona, persona_variables)

    # Interpolate instructions (RAG_CONTEXT)
    interpolated_instructions = interpolate(instructions, { "RAG_CONTEXT" => context })

    # Combine persona + instructions + question title
    <<~PROMPT
      #{interpolated_persona}

      #{interpolated_instructions}

      QUESTION TITLE: #{title}
    PROMPT
  end

  # Get the effective persona (space custom or system default)
  # @return [String] The persona prompt
  def effective_persona
    if space.qa_wizard_prompt.present?
      space.qa_wizard_prompt
    else
      SearchSetting.qa_wizard_persona
    end
  end

  # Check if the space has a custom persona
  def custom_prompt?
    space.qa_wizard_prompt.present?
  end

  private

  def instructions_template
    @instructions_template ||= File.read(INSTRUCTIONS_PATH)
  end

  def space_description_section
    return "" if space.description.blank?

    "Space Description: #{space.description}"
  end

  # Build the RAG context string with attribution metadata
  def build_rag_context(chunks)
    return "(No relevant content found in the knowledge base)" if chunks.empty?

    chunks.map.with_index(1) do |chunk, index|
      format_chunk_with_attribution(chunk, index)
    end.join("\n\n---\n\n")
  end

  # Format a chunk with full attribution metadata
  def format_chunk_with_attribution(chunk, index)
    source = chunk.chunkable
    metadata = extract_source_metadata(source)

    <<~CHUNK
      [Source #{index}]
      Type: #{metadata[:type]}
      ID: #{metadata[:id]}
      Title: #{metadata[:title]}
      Author: #{metadata[:author]}
      Published: #{metadata[:published_at]}
      URL: #{metadata[:url]}

      #{chunk.content}
    CHUNK
  end

  # Extract metadata from a source (Article, Question, etc.)
  # Note: user and question associations are required (belongs_to default),
  # and created_at is always set by Rails, so no nil checks needed.
  def extract_source_metadata(source)
    case source
    when Article
      {
        type: "Article",
        id: source.id,
        title: source.title,
        author: source.user.display_name,
        published_at: source.created_at.strftime("%Y-%m-%d"),
        url: Rails.application.routes.url_helpers.article_path(source)
      }
    when Question
      {
        type: "Question",
        id: source.id,
        title: source.title,
        author: source.user.display_name,
        published_at: source.created_at.strftime("%Y-%m-%d"),
        url: Rails.application.routes.url_helpers.question_path(source)
      }
    when Answer
      {
        type: "Answer",
        id: source.id,
        title: "Answer to: #{source.question.title}",
        author: source.user.display_name,
        published_at: source.created_at.strftime("%Y-%m-%d"),
        url: Rails.application.routes.url_helpers.question_path(source.question)
      }
    else
      {
        type: source.class.name,
        id: source.try(:id) || "N/A",
        title: source.try(:title) || "Untitled",
        author: "Unknown",
        published_at: "Unknown",
        url: "#"
      }
    end
  end

  # Interpolate variables in the template
  # @param template [String] The template with {{VARIABLE}} placeholders
  # @param variables [Hash] Variable name => value mapping
  # @return [String] The interpolated template
  def interpolate(template, variables)
    result = template.dup

    variables.each do |name, value|
      result.gsub!("{{#{name}}}", value.to_s)
    end

    result
  end
end
