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

    # Pre-process: Redcarpet requires blank lines before certain block elements
    processed_text = preprocess_fenced_code_blocks(text)
    processed_text = preprocess_lists(processed_text)

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

  def preprocess_lists(text)
    # Redcarpet requires a blank line before lists to recognize them
    # LLMs often generate lists immediately after paragraphs without blank lines
    #
    # Strategy: Process line by line, adding blank lines before list starts
    lines = text.split("\n", -1) # -1 preserves trailing empty strings
    result_lines = []

    lines.each_with_index do |line, index|
      # Check if this line starts a list
      is_list_start = line.match?(/^\d+\. /) || line.match?(/^[-*] /)

      if is_list_start && index > 0
        prev_line = lines[index - 1]
        prev_is_list_item = prev_line.match?(/^\d+\. /) || prev_line.match?(/^[-*] /)
        prev_is_blank = prev_line.strip.empty?

        # Add blank line if previous line is not a list item and not already blank
        result_lines << "" if !prev_is_list_item && !prev_is_blank
      end

      result_lines << line
    end

    result_lines.join("\n")
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
