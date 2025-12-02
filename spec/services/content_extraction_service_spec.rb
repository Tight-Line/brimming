# frozen_string_literal: true

require "rails_helper"

RSpec.describe ContentExtractionService do
  describe ".extract" do
    context "with markdown content" do
      it "returns the body as-is" do
        article = build(:article, content_type: "markdown", body: "# Hello\n\nThis is markdown.")
        expect(described_class.extract(article)).to eq("# Hello\n\nThis is markdown.")
      end

      it "returns empty string for nil body" do
        article = build(:article, content_type: "markdown", body: nil)
        expect(described_class.extract(article)).to eq("")
      end
    end

    context "with html content" do
      it "strips HTML tags" do
        article = build(:article, :html, body: "<p>Hello <strong>World</strong></p>")
        expect(described_class.extract(article)).to eq("Hello World")
      end

      it "returns empty string for nil body" do
        article = build(:article, :html, body: nil)
        expect(described_class.extract(article)).to eq("")
      end

      it "returns empty string for blank body" do
        article = build(:article, :html, body: "")
        expect(described_class.extract(article)).to eq("")
      end
    end

    context "with plain text content" do
      it "returns the body as-is" do
        article = build(:article, :plain_text, body: "Plain text content")
        expect(described_class.extract(article)).to eq("Plain text content")
      end
    end

    context "with pdf content" do
      it "returns empty string when no file attached" do
        article = build(:article, :pdf)
        expect(described_class.extract(article)).to eq("")
      end

      it "extracts text from attached PDF file" do
        article = build(:article, :pdf)
        # Mock the file attachment and PDF reader
        mock_file = double("file", path: "/tmp/test.pdf")
        mock_page = double("page", text: "PDF content here")
        mock_reader = double("reader", pages: [ mock_page ])

        allow(article).to receive_message_chain(:original_file, :attached?).and_return(true)
        allow(article).to receive_message_chain(:original_file, :open).and_yield(mock_file)
        allow(PDF::Reader).to receive(:new).with(mock_file.path).and_return(mock_reader)

        expect(described_class.extract(article)).to eq("PDF content here")
      end

      it "returns empty string when PDF is malformed" do
        article = build(:article, :pdf)
        mock_file = double("file", path: "/tmp/test.pdf")

        allow(article).to receive_message_chain(:original_file, :attached?).and_return(true)
        allow(article).to receive_message_chain(:original_file, :open).and_yield(mock_file)
        allow(PDF::Reader).to receive(:new).and_raise(PDF::Reader::MalformedPDFError.new("Malformed PDF"))

        expect(Rails.logger).to receive(:warn).with(/Failed to extract PDF/)
        expect(described_class.extract(article)).to eq("")
      end
    end

    context "with docx content" do
      it "returns empty string when no file attached" do
        article = build(:article, :docx)
        expect(described_class.extract(article)).to eq("")
      end

      it "extracts text from attached DOCX file" do
        article = build(:article, :docx)
        mock_file = double("file", path: "/tmp/test.docx")
        mock_para1 = double("para", text: "Paragraph one")
        mock_para2 = double("para", text: "Paragraph two")
        mock_doc = double("doc", paragraphs: [ mock_para1, mock_para2 ])

        allow(article).to receive_message_chain(:original_file, :attached?).and_return(true)
        allow(article).to receive_message_chain(:original_file, :open).and_yield(mock_file)
        allow(Docx::Document).to receive(:open).with(mock_file.path).and_return(mock_doc)

        result = described_class.extract(article)
        expect(result).to include("Paragraph one")
        expect(result).to include("Paragraph two")
      end

      it "skips blank paragraphs in DOCX" do
        article = build(:article, :docx)
        mock_file = double("file", path: "/tmp/test.docx")
        mock_para1 = double("para", text: "Content")
        mock_para_blank = double("para", text: "")
        mock_para_nil = double("para", text: nil)
        mock_doc = double("doc", paragraphs: [ mock_para1, mock_para_blank, mock_para_nil ])

        allow(article).to receive_message_chain(:original_file, :attached?).and_return(true)
        allow(article).to receive_message_chain(:original_file, :open).and_yield(mock_file)
        allow(Docx::Document).to receive(:open).with(mock_file.path).and_return(mock_doc)

        result = described_class.extract(article)
        expect(result).to eq("Content")
      end

      it "returns empty string when DOCX extraction fails" do
        article = build(:article, :docx)
        mock_file = double("file", path: "/tmp/test.docx")

        allow(article).to receive_message_chain(:original_file, :attached?).and_return(true)
        allow(article).to receive_message_chain(:original_file, :open).and_yield(mock_file)
        allow(Docx::Document).to receive(:open).and_raise(StandardError.new("Invalid DOCX"))

        expect(Rails.logger).to receive(:warn).with(/Failed to extract DOCX/)
        expect(described_class.extract(article)).to eq("")
      end
    end

    context "with xlsx content" do
      it "returns empty string when no file attached" do
        article = build(:article, :xlsx)
        expect(described_class.extract(article)).to eq("")
      end

      it "extracts text from attached XLSX file" do
        article = build(:article, :xlsx)
        mock_file = double("file", path: "/tmp/test.xlsx")
        mock_sheet = double("sheet", name: "Sheet1")
        mock_spreadsheet = double("spreadsheet", sheets: [ "Sheet1" ])

        allow(article).to receive_message_chain(:original_file, :attached?).and_return(true)
        allow(article).to receive_message_chain(:original_file, :open).and_yield(mock_file)
        allow(Roo::Spreadsheet).to receive(:open).with(mock_file.path, extension: :xlsx).and_return(mock_spreadsheet)
        allow(mock_spreadsheet).to receive(:sheet).with("Sheet1").and_return(mock_sheet)
        allow(mock_sheet).to receive(:each_row_streaming).and_yield([ double(value: "A1"), double(value: "B1") ])

        result = described_class.extract(article)
        expect(result).to include("Sheet1")
        expect(result).to include("A1")
      end

      it "handles nil cell values in XLSX" do
        article = build(:article, :xlsx)
        mock_file = double("file", path: "/tmp/test.xlsx")
        mock_sheet = double("sheet", name: "Sheet1")
        mock_spreadsheet = double("spreadsheet", sheets: [ "Sheet1" ])

        allow(article).to receive_message_chain(:original_file, :attached?).and_return(true)
        allow(article).to receive_message_chain(:original_file, :open).and_yield(mock_file)
        allow(Roo::Spreadsheet).to receive(:open).with(mock_file.path, extension: :xlsx).and_return(mock_spreadsheet)
        allow(mock_spreadsheet).to receive(:sheet).with("Sheet1").and_return(mock_sheet)
        # Mix of nil cells (cell object with nil value) and actual values
        allow(mock_sheet).to receive(:each_row_streaming).and_yield([ double(value: nil), double(value: "Value") ])

        result = described_class.extract(article)
        expect(result).to include("Value")
      end

      it "handles nil cell objects in XLSX (sparse spreadsheet)" do
        article = build(:article, :xlsx)
        mock_file = double("file", path: "/tmp/test.xlsx")
        mock_sheet = double("sheet", name: "Sheet1")
        mock_spreadsheet = double("spreadsheet", sheets: [ "Sheet1" ])

        allow(article).to receive_message_chain(:original_file, :attached?).and_return(true)
        allow(article).to receive_message_chain(:original_file, :open).and_yield(mock_file)
        allow(Roo::Spreadsheet).to receive(:open).with(mock_file.path, extension: :xlsx).and_return(mock_spreadsheet)
        allow(mock_spreadsheet).to receive(:sheet).with("Sheet1").and_return(mock_sheet)
        # Sparse spreadsheet with nil cell objects (not just nil values)
        allow(mock_sheet).to receive(:each_row_streaming).and_yield([ nil, double(value: "Data") ])

        result = described_class.extract(article)
        expect(result).to include("Data")
      end

      it "skips blank rows in XLSX" do
        article = build(:article, :xlsx)
        mock_file = double("file", path: "/tmp/test.xlsx")
        mock_sheet = double("sheet", name: "Sheet1")
        mock_spreadsheet = double("spreadsheet", sheets: [ "Sheet1" ])

        allow(article).to receive_message_chain(:original_file, :attached?).and_return(true)
        allow(article).to receive_message_chain(:original_file, :open).and_yield(mock_file)
        allow(Roo::Spreadsheet).to receive(:open).with(mock_file.path, extension: :xlsx).and_return(mock_spreadsheet)
        allow(mock_spreadsheet).to receive(:sheet).with("Sheet1").and_return(mock_sheet)
        # Yield blank rows that should be skipped
        allow(mock_sheet).to receive(:each_row_streaming)
          .and_yield([ double(value: "Content") ])
          .and_yield([ double(value: ""), double(value: nil) ])

        result = described_class.extract(article)
        expect(result).to include("Content")
        # The blank row shouldn't add any actual content
      end

      it "returns empty string when XLSX extraction fails" do
        article = build(:article, :xlsx)
        mock_file = double("file", path: "/tmp/test.xlsx")

        allow(article).to receive_message_chain(:original_file, :attached?).and_return(true)
        allow(article).to receive_message_chain(:original_file, :open).and_yield(mock_file)
        allow(Roo::Spreadsheet).to receive(:open).and_raise(StandardError.new("Invalid XLSX"))

        expect(Rails.logger).to receive(:warn).with(/Failed to extract XLSX/)
        expect(described_class.extract(article)).to eq("")
      end
    end

    context "with context" do
      it "prepends context to content" do
        article = build(:article, :with_context, body: "Article body")
        result = described_class.extract(article)
        expect(result).to start_with("Context: This article provides guidance")
        expect(result).to include("Article body")
      end

      it "does not prepend context when blank" do
        article = build(:article, body: "Article body", context: "")
        result = described_class.extract(article)
        expect(result).to eq("Article body")
      end
    end

    context "content truncation" do
      it "truncates content exceeding MAX_CONTENT_LENGTH" do
        long_body = "x" * 150_000
        article = build(:article, content_type: "markdown", body: long_body)
        result = described_class.extract(article)
        expect(result.length).to eq(described_class::MAX_CONTENT_LENGTH)
      end

      it "does not truncate content within limit" do
        body = "x" * 1000
        article = build(:article, content_type: "markdown", body: body)
        result = described_class.extract(article)
        expect(result.length).to eq(1000)
      end
    end
  end
end
