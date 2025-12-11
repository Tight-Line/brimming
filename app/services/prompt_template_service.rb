# frozen_string_literal: true

# Service for loading and processing prompt templates with partial support
#
# Supports:
# - Variable interpolation: {{VARIABLE_NAME}}
# - Partial inclusion: {{> _partial_name}}
#
# Partials are loaded from config/prompts/ and must be prefixed with underscore.
#
# Usage:
#   template = PromptTemplateService.load("ai_answer_rag.md")
#   prompt = PromptTemplateService.interpolate(template, { "QUERY" => "How do I...?" })
#
class PromptTemplateService
  PROMPTS_DIR = Rails.root.join("config/prompts")

  # Pattern to match partial includes: {{> _partial_name}}
  PARTIAL_PATTERN = /\{\{>\s*(_[\w]+)\s*\}\}/

  class << self
    # Load a template file and resolve all partials
    # @param filename [String] The template filename (e.g., "ai_answer_rag.md")
    # @return [String] The template with partials resolved
    def load(filename)
      path = PROMPTS_DIR.join(filename)
      template = File.read(path)
      resolve_partials(template)
    end

    # Interpolate variables in a template
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

    # Load and interpolate in one step
    # @param filename [String] The template filename
    # @param variables [Hash] Variable name => value mapping
    # @return [String] The fully processed template
    def render(filename, variables = {})
      template = load(filename)
      interpolate(template, variables)
    end

    private

    # Resolve all partial includes in a template
    # @param template [String] The template with {{> _partial}} placeholders
    # @return [String] The template with partials expanded
    def resolve_partials(template)
      template.gsub(PARTIAL_PATTERN) do |_match|
        partial_name = ::Regexp.last_match(1)
        load_partial(partial_name)
      end
    end

    # Load a partial file
    # @param name [String] The partial name (e.g., "_markdown_formatting_rules")
    # @return [String] The partial content
    def load_partial(name)
      path = PROMPTS_DIR.join("#{name}.md")

      unless path.exist?
        raise ArgumentError, "Partial not found: #{name}.md in #{PROMPTS_DIR}"
      end

      content = File.read(path)
      # Partials can include other partials (recursive resolution)
      resolve_partials(content)
    end
  end
end
