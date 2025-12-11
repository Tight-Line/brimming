# frozen_string_literal: true

module MarkdownHelper
  # Custom Redcarpet renderer with Rouge syntax highlighting
  class HTMLWithRouge < Redcarpet::Render::HTML
    def block_code(code, language)
      language = language.to_s.strip
      language = "text" if language.empty?

      lexer = Rouge::Lexer.find_fancy(language, code) || Rouge::Lexers::PlainText.new
      formatter = Rouge::Formatters::HTMLInline.new(Rouge::Themes::Base16::Monokai.new)

      highlighted = formatter.format(lexer.lex(code))
      %(<pre class="highlight #{CGI.escapeHTML(language)}"><code>#{highlighted}</code></pre>)
    end

    def codespan(code)
      %(<code class="inline-code">#{CGI.escapeHTML(code)}</code>)
    end
  end

  def markdown(text)
    return "" if text.blank?

    # Pre-process: ensure blank line before fenced code blocks
    # Redcarpet requires this for proper parsing
    processed_text = preprocess_fenced_code_blocks(text)

    renderer = HTMLWithRouge.new(
      hard_wrap: false,
      link_attributes: { rel: "nofollow noopener", target: "_blank" }
    )

    markdown_parser = Redcarpet::Markdown.new(
      renderer,
      autolink: true,
      fenced_code_blocks: true,
      no_intra_emphasis: true,
      strikethrough: true,
      superscript: true,
      tables: true,
      underline: true
    )

    sanitize_markdown(markdown_parser.render(processed_text)).html_safe
  end

  def preprocess_fenced_code_blocks(text)
    # Handle indented fenced code blocks (common in LLM output inside list items)
    # Redcarpet doesn't recognize ``` when indented, so we need to:
    # 1. Remove leading whitespace from fence lines
    # 2. Ensure blank line before opening fence
    result = text.dup

    # Remove indentation from fenced code blocks (handles ```lang and closing ```)
    # This regex finds indented ``` lines and removes the leading whitespace
    result = result.gsub(/^[ \t]+(```\w*)/, '\1')  # Opening fence with optional language
    result = result.gsub(/^[ \t]+(```)$/, '\1')    # Closing fence

    # Add blank line before opening ``` with language identifier if not already present
    # Use \w+ (not \w?) to only match opening fences with language, not closing ```
    result.gsub(/([^\n])\n(```\w)/, "\\1\n\n\\2")
  end

  private

  def sanitize_markdown(html)
    # Allow common HTML elements and attributes for rendered markdown
    # Using ActionView::Base.safe_list_sanitizer for more control
    scrubber = Rails::HTML5::SafeListSanitizer.new
    scrubber.sanitize(
      html,
      tags: %w[
        p br strong em b i u s del strike
        h1 h2 h3 h4 h5 h6
        ul ol li
        a
        pre code span
        blockquote
        table thead tbody tr th td
        hr
      ],
      attributes: %w[href rel target class style]
    )
  end
end
