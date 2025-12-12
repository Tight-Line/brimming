# frozen_string_literal: true

require "pdf-reader"
require "docx"
require "roo"

# Service for extracting text content from articles.
#
# Handles multiple content types:
# - markdown: Returns body as-is (with optional context)
# - html: Strips HTML tags
# - txt: Returns body as-is (with optional context)
# - pdf/docx/xlsx: Placeholder for file extraction (requires additional gems)
#
# Usage:
#   text = ContentExtractionService.extract(article)
#
class ContentExtractionService
  class ExtractionError < StandardError; end

  # Maximum length for extracted content (to prevent excessive embedding costs)
  MAX_CONTENT_LENGTH = 100_000

  def self.extract(article)
    new(article).extract
  end

  def initialize(article)
    @article = article
  end

  def extract
    content = extract_content
    return "" if content.blank?

    # Prepend context if present
    if @article.context.present?
      content = "Context: #{@article.context}\n\n#{content}"
    end

    # Truncate if necessary
    truncate_content(content)
  end

  private

  # Extractors by content type (all types are validated, so no fallback needed)
  EXTRACTORS = {
    "markdown" => :extract_markdown,
    "html" => :extract_html,
    "txt" => :extract_plain_text,
    "pdf" => :extract_pdf,
    "docx" => :extract_docx,
    "xlsx" => :extract_xlsx,
    "webpage" => :extract_webpage
  }.freeze

  def extract_content
    method_name = EXTRACTORS[@article.content_type]
    send(method_name)
  end

  def extract_markdown
    @article.body.to_s
  end

  def extract_html
    return "" if @article.body.blank?

    # Strip HTML tags to get plain text
    ActionController::Base.helpers.strip_tags(@article.body)
  end

  def extract_plain_text
    @article.body.to_s
  end

  def extract_pdf
    return "" unless @article.original_file.attached?

    text_parts = []
    @article.original_file.open do |file|
      reader = PDF::Reader.new(file.path)
      reader.pages.each do |page|
        text_parts << page.text
      end
    end
    text_parts.join("\n\n")
  rescue PDF::Reader::MalformedPDFError, PDF::Reader::UnsupportedFeatureError => e
    Rails.logger.warn("[ContentExtractionService] Failed to extract PDF: #{e.message}")
    ""
  end

  def extract_docx
    return "" unless @article.original_file.attached?

    text_parts = []
    @article.original_file.open do |file|
      doc = Docx::Document.open(file.path)
      doc.paragraphs.each do |para|
        text_parts << para.text unless para.text.blank?
      end
    end
    text_parts.join("\n\n")
  rescue StandardError => e
    Rails.logger.warn("[ContentExtractionService] Failed to extract DOCX: #{e.message}")
    ""
  end

  def extract_xlsx
    return "" unless @article.original_file.attached?

    text_parts = []
    @article.original_file.open do |file|
      xlsx = Roo::Spreadsheet.open(file.path, extension: :xlsx)
      xlsx.sheets.each do |sheet_name|
        sheet = xlsx.sheet(sheet_name)
        text_parts << "Sheet: #{sheet_name}"
        sheet.each_row_streaming do |row|
          row_text = row.map { |cell| cell&.value.to_s }.reject(&:blank?).join(" | ")
          text_parts << row_text unless row_text.blank?
        end
        text_parts << ""
      end
    end
    text_parts.join("\n")
  rescue StandardError => e
    Rails.logger.warn("[ContentExtractionService] Failed to extract XLSX: #{e.message}")
    ""
  end

  def extract_webpage
    # Webpage content is already markdown stored in the body
    @article.body.to_s
  end

  def truncate_content(content)
    return content if content.length <= MAX_CONTENT_LENGTH

    content[0, MAX_CONTENT_LENGTH]
  end
end
