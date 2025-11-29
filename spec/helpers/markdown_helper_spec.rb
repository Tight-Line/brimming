# frozen_string_literal: true

require "rails_helper"

RSpec.describe MarkdownHelper do
  describe "#markdown" do
    it "returns empty string for nil input" do
      expect(helper.markdown(nil)).to eq("")
    end

    it "returns empty string for blank input" do
      expect(helper.markdown("")).to eq("")
      expect(helper.markdown("   ")).to eq("")
    end

    it "renders paragraphs" do
      result = helper.markdown("Hello world")
      expect(result).to include("<p>Hello world</p>")
    end

    it "renders bold text" do
      result = helper.markdown("**bold text**")
      expect(result).to include("<strong>bold text</strong>")
    end

    it "renders italic text" do
      result = helper.markdown("*italic text*")
      expect(result).to include("<em>italic text</em>")
    end

    it "renders inline code with inline-code class" do
      result = helper.markdown("Use `config/routes.rb` for routes")
      expect(result).to include('<code class="inline-code">config/routes.rb</code>')
    end

    it "renders fenced code blocks with syntax highlighting" do
      code = "```ruby\ndef hello\n  puts 'world'\nend\n```"
      result = helper.markdown(code)
      expect(result).to include('<pre class="highlight ruby">')
      expect(result).to include("<code>")
      expect(result).to include("</code></pre>")
      # Should have inline styles from Rouge
      expect(result).to include("style=")
    end

    it "renders code blocks without language as text" do
      code = "```\nplain text\n```"
      result = helper.markdown(code)
      expect(result).to include('<pre class="highlight text">')
      expect(result).to include("plain text")
    end

    it "renders links" do
      result = helper.markdown("[Google](https://google.com)")
      expect(result).to include('href="https://google.com"')
    end

    it "renders unordered lists" do
      result = helper.markdown("- item 1\n- item 2")
      expect(result).to include("<ul>")
      expect(result).to include("<li>")
      expect(result).to include("item 1")
      expect(result).to include("item 2")
    end

    it "renders ordered lists" do
      result = helper.markdown("1. first\n2. second")
      expect(result).to include("<ol>")
      expect(result).to include("<li>")
    end

    it "renders blockquotes" do
      result = helper.markdown("> quoted text")
      expect(result).to include("<blockquote>")
      expect(result).to include("quoted text")
    end

    it "renders headings" do
      result = helper.markdown("## Heading Two")
      expect(result).to include("<h2>Heading Two</h2>")
    end

    it "renders strikethrough" do
      result = helper.markdown("~~deleted~~")
      expect(result).to include("<del>deleted</del>")
    end

    it "sanitizes script tags" do
      result = helper.markdown("<script>alert('xss')</script>")
      expect(result).not_to include("<script>")
    end

    it "sanitizes onclick attributes" do
      result = helper.markdown('<a onclick="alert()" href="#">click</a>')
      expect(result).not_to include("onclick")
    end

    it "auto-links URLs" do
      result = helper.markdown("Check out https://example.com today")
      expect(result).to include('href="https://example.com"')
    end

    it "renders tables" do
      table = "| A | B |\n|---|---|\n| 1 | 2 |"
      result = helper.markdown(table)
      expect(result).to include("<table>")
      expect(result).to include("<th>")
      expect(result).to include("<td>")
    end

    it "preserves line breaks in paragraphs" do
      result = helper.markdown("line1\nline2")
      # Without hard_wrap, single newlines don't become <br>
      # Double newlines create new paragraphs
      expect(result).to include("line1")
      expect(result).to include("line2")
    end

    it "handles fenced code blocks without preceding blank line" do
      # Redcarpet requires blank line before ```, but we preprocess to add it
      result = helper.markdown("text:\n```ruby\ncode\n```")
      expect(result).to include('<pre class="highlight ruby">')
      expect(result).to include("code")
    end

    it "escapes HTML in inline code" do
      result = helper.markdown("Use `<script>` tag")
      expect(result).to include("&lt;script&gt;")
      expect(result).not_to include("<script>")
    end

    it "handles unknown language gracefully" do
      code = "```nonexistent_lang\nsome code\n```"
      result = helper.markdown(code)
      expect(result).to include('<pre class="highlight')
      expect(result).to include("some code")
    end
  end

  describe "#preprocess_fenced_code_blocks" do
    it "adds blank line before fenced code blocks with language" do
      input = "text:\n```ruby\ncode\n```"
      result = helper.preprocess_fenced_code_blocks(input)
      expect(result).to eq("text:\n\n```ruby\ncode\n```")
    end

    it "preserves existing blank lines" do
      input = "text:\n\n```ruby\ncode\n```"
      result = helper.preprocess_fenced_code_blocks(input)
      expect(result).to eq("text:\n\n```ruby\ncode\n```")
    end

    it "handles multiple code blocks with languages" do
      input = "a:\n```ruby\ncode1\n```\nb:\n```js\ncode2\n```"
      result = helper.preprocess_fenced_code_blocks(input)
      expect(result).to include("a:\n\n```ruby")
      expect(result).to include("b:\n\n```js")
    end

    it "does not add blank line before closing fences" do
      input = "text:\n```ruby\ncode\n```\nmore"
      result = helper.preprocess_fenced_code_blocks(input)
      # Should only add blank before opening fence, not closing
      expect(result).to eq("text:\n\n```ruby\ncode\n```\nmore")
    end
  end

  describe MarkdownHelper::HTMLWithRouge do
    let(:renderer) { described_class.new }

    describe "#block_code" do
      it "renders code with syntax highlighting" do
        result = renderer.block_code("puts 'hello'", "ruby")
        expect(result).to include('<pre class="highlight ruby">')
        expect(result).to include("<code>")
      end

      it "uses text language for nil" do
        result = renderer.block_code("plain", nil)
        expect(result).to include('<pre class="highlight text">')
      end

      it "uses text language for empty string" do
        result = renderer.block_code("plain", "")
        expect(result).to include('<pre class="highlight text">')
      end

      it "handles unknown language" do
        result = renderer.block_code("code", "xyz123")
        expect(result).to include('<pre class="highlight')
      end

      it "escapes language name in class" do
        result = renderer.block_code("code", "<script>")
        expect(result).not_to include("class=\"highlight <script>")
      end
    end

    describe "#codespan" do
      it "wraps code in code tag with class" do
        result = renderer.codespan("inline")
        expect(result).to eq('<code class="inline-code">inline</code>')
      end

      it "escapes HTML" do
        result = renderer.codespan("<script>alert()</script>")
        expect(result).to include("&lt;script&gt;")
        expect(result).not_to include("<script>")
      end
    end
  end
end
