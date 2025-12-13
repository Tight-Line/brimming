# frozen_string_literal: true

require "rails_helper"

RSpec.describe WebPageFetchService do
  let(:provider) { create(:reader_provider, :enabled, api_key: "test-key", api_endpoint: "https://r.jina.ai") }
  let(:url) { "https://example.com/article" }
  let(:service) { described_class.new(url, provider: provider) }

  describe "#fetch" do
    context "when no provider is configured" do
      let(:service) { described_class.new(url, provider: nil) }

      before { ReaderProvider.destroy_all }

      it "returns a failure result" do
        result = service.fetch
        expect(result).to be_failure
        expect(result.error).to eq("No reader provider configured")
      end
    end

    context "with an invalid URL" do
      let(:url) { "not-a-valid-url" }

      it "returns a failure result" do
        result = service.fetch
        expect(result).to be_failure
        expect(result.error).to eq("Invalid URL")
      end
    end

    context "with a non-HTTP URL" do
      let(:url) { "ftp://example.com/file" }

      it "returns a failure result" do
        result = service.fetch
        expect(result).to be_failure
        expect(result.error).to eq("Invalid URL")
      end
    end

    context "with an invalid provider endpoint (non-HTTP scheme)" do
      let(:provider) do
        p = create(:reader_provider, :enabled, api_key: "test-key")
        p.update_column(:api_endpoint, "not-a-valid-url")
        p
      end

      it "returns a failure result" do
        result = service.fetch
        expect(result).to be_failure
        expect(result.error).to eq("Invalid reader provider endpoint")
      end
    end

    context "with an unparseable provider endpoint" do
      let(:provider) do
        p = create(:reader_provider, :enabled, api_key: "test-key")
        p.update_column(:api_endpoint, "http://[invalid")
        p
      end

      it "returns a failure result" do
        result = service.fetch
        expect(result).to be_failure
        expect(result.error).to eq("Invalid reader provider endpoint")
      end
    end

    context "with a non-HTTP provider endpoint" do
      let(:provider) do
        p = create(:reader_provider, :enabled, api_key: "test-key")
        p.update_column(:api_endpoint, "ftp://example.com")
        p
      end

      it "returns a failure result" do
        result = service.fetch
        expect(result).to be_failure
        expect(result.error).to eq("Invalid reader provider endpoint")
      end
    end

    context "with a blank provider endpoint" do
      let(:provider) do
        p = create(:reader_provider, :enabled, api_key: "test-key")
        p.update_column(:api_endpoint, nil)
        p
      end

      it "returns a failure result" do
        result = service.fetch
        expect(result).to be_failure
        expect(result.error).to eq("Invalid reader provider endpoint")
      end
    end

    context "with a valid URL and provider" do
      let(:markdown_content) { "# Hello World\n\nThis is the article content." }
      let(:json_response) { { "data" => { "content" => markdown_content, "title" => "Hello World" } }.to_json }

      before do
        stub_request(:get, "https://r.jina.ai/https://example.com/article")
          .with(headers: { "Authorization" => "Bearer test-key", "Accept" => "application/json" })
          .to_return(status: 200, body: json_response)
      end

      it "returns the fetched content" do
        result = service.fetch
        expect(result).to be_success
        expect(result.content).to eq(markdown_content)
      end
    end

    context "when provider has no API key" do
      let(:provider) { create(:reader_provider, :enabled, api_key: nil, api_endpoint: "https://r.jina.ai") }
      let(:json_response) { { "data" => { "content" => "Content" } }.to_json }

      before do
        stub_request(:get, "https://r.jina.ai/https://example.com/article")
          .with(headers: { "Accept" => "application/json" })
          .to_return(status: 200, body: json_response)
      end

      it "still makes the request without Authorization header" do
        result = service.fetch
        expect(result).to be_success

        expect(WebMock).to have_requested(:get, "https://r.jina.ai/https://example.com/article")
          .with { |req| !req.headers.key?("Authorization") }
      end
    end

    context "when response has no content" do
      let(:json_response) { { "data" => { "title" => "Empty Page" } }.to_json }

      before do
        stub_request(:get, "https://r.jina.ai/https://example.com/article")
          .to_return(status: 200, body: json_response)
      end

      it "returns a failure result" do
        result = service.fetch
        expect(result).to be_failure
        expect(result.error).to include("No content found")
      end
    end

    context "when response is invalid JSON" do
      before do
        stub_request(:get, "https://r.jina.ai/https://example.com/article")
          .to_return(status: 200, body: "not valid json {")
      end

      it "returns a failure result" do
        result = service.fetch
        expect(result).to be_failure
        expect(result.error).to include("Failed to parse response")
      end
    end

    context "when the request times out" do
      before do
        stub_request(:get, "https://r.jina.ai/https://example.com/article")
          .to_timeout
      end

      it "returns a failure result" do
        result = service.fetch
        expect(result).to be_failure
        expect(result.error).to eq("Request timed out while fetching the page")
      end
    end

    context "when authentication fails" do
      before do
        stub_request(:get, "https://r.jina.ai/https://example.com/article")
          .to_return(status: 401)
      end

      it "returns a failure result" do
        result = service.fetch
        expect(result).to be_failure
        expect(result.error).to include("Authentication failed")
      end
    end

    context "when access is forbidden" do
      before do
        stub_request(:get, "https://r.jina.ai/https://example.com/article")
          .to_return(status: 403)
      end

      it "returns a failure result" do
        result = service.fetch
        expect(result).to be_failure
        expect(result.error).to include("Access forbidden")
      end
    end

    context "when the page is not found" do
      before do
        stub_request(:get, "https://r.jina.ai/https://example.com/article")
          .to_return(status: 404)
      end

      it "returns a failure result" do
        result = service.fetch
        expect(result).to be_failure
        expect(result.error).to include("Page not found")
      end
    end

    context "when rate limited" do
      before do
        stub_request(:get, "https://r.jina.ai/https://example.com/article")
          .to_return(status: 429)
      end

      it "returns a failure result" do
        result = service.fetch
        expect(result).to be_failure
        expect(result.error).to include("Rate limit exceeded")
      end
    end

    context "when server error occurs" do
      before do
        stub_request(:get, "https://r.jina.ai/https://example.com/article")
          .to_return(status: 500)
      end

      it "returns a failure result" do
        result = service.fetch
        expect(result).to be_failure
        expect(result.error).to include("Reader service error")
      end
    end

    context "when an unexpected response code is returned" do
      before do
        stub_request(:get, "https://r.jina.ai/https://example.com/article")
          .to_return(status: [ 418, "I'm a teapot" ])
      end

      it "returns a failure result with the response code" do
        result = service.fetch
        expect(result).to be_failure
        expect(result.error).to include("Unexpected response: 418")
      end
    end

    context "when connection is refused" do
      before do
        stub_request(:get, "https://r.jina.ai/https://example.com/article")
          .to_raise(Errno::ECONNREFUSED)
      end

      it "returns a failure result" do
        result = service.fetch
        expect(result).to be_failure
        expect(result.error).to include("Failed to fetch page")
      end
    end

    context "when socket error occurs" do
      before do
        stub_request(:get, "https://r.jina.ai/https://example.com/article")
          .to_raise(SocketError.new("Failed to open TCP connection"))
      end

      it "returns a failure result with connection error" do
        result = service.fetch
        expect(result).to be_failure
        expect(result.error).to include("Could not connect")
      end
    end

    context "with an invalid URI that cannot be parsed" do
      let(:url) { "http://[invalid" }

      it "returns a failure result" do
        result = service.fetch
        expect(result).to be_failure
        expect(result.error).to eq("Invalid URL")
      end
    end

    context "with unsupported provider type" do
      let(:provider) do
        p = create(:reader_provider)
        p.update_column(:provider_type, "unknown_provider")
        p
      end

      it "returns a failure result" do
        result = service.fetch
        expect(result).to be_failure
        expect(result.error).to include("Unsupported provider type")
      end
    end
  end

  describe "Firecrawl provider" do
    let(:provider) { create(:reader_provider, :enabled, :firecrawl) }
    let(:service) { described_class.new(url, provider: provider) }

    before do
      allow(Firecrawl).to receive(:api_key)
    end

    context "with a valid URL and provider" do
      let(:markdown_content) { "# Hello World\n\nThis is the article content." }
      let(:mock_response) { double("Response", success?: true, markdown: markdown_content) }

      before do
        allow(Firecrawl).to receive(:scrape).with(url, formats: [ "markdown" ], only_main_content: true).and_return(mock_response)
      end

      it "returns the fetched content" do
        result = service.fetch
        expect(result).to be_success
        expect(result.content).to eq(markdown_content)
      end

      it "sets the API key" do
        service.fetch
        expect(Firecrawl).to have_received(:api_key).with(provider.api_key)
      end
    end

    context "when Firecrawl returns success: false" do
      let(:mock_response) { double("Response", success?: false, error: "Failed to scrape") }

      before do
        allow(Firecrawl).to receive(:scrape).and_return(mock_response)
      end

      it "returns a failure result" do
        result = service.fetch
        expect(result).to be_failure
        expect(result.error).to include("Firecrawl error")
      end
    end

    context "when Firecrawl response has no markdown" do
      let(:mock_response) { double("Response", success?: true, markdown: nil) }

      before do
        allow(Firecrawl).to receive(:scrape).and_return(mock_response)
      end

      it "returns a failure result" do
        result = service.fetch
        expect(result).to be_failure
        expect(result.error).to include("No content found")
      end
    end

    context "when Firecrawl response has blank markdown" do
      let(:mock_response) { double("Response", success?: true, markdown: "") }

      before do
        allow(Firecrawl).to receive(:scrape).and_return(mock_response)
      end

      it "returns a failure result" do
        result = service.fetch
        expect(result).to be_failure
        expect(result.error).to include("No content found")
      end
    end

    context "when Firecrawl raises an error" do
      before do
        allow(Firecrawl).to receive(:scrape).and_raise(StandardError.new("Service unavailable"))
      end

      it "returns a failure result" do
        result = service.fetch
        expect(result).to be_failure
        expect(result.error).to include("Failed to fetch page")
        expect(result.error).to include("Service unavailable")
      end
    end

    context "when Firecrawl returns failure with no error message" do
      let(:mock_response) { double("Response", success?: false, error: nil) }

      before do
        allow(Firecrawl).to receive(:scrape).and_return(mock_response)
      end

      it "returns a failure result with unknown error" do
        result = service.fetch
        expect(result).to be_failure
        expect(result.error).to include("Unknown error")
      end
    end
  end

  describe "Result" do
    describe ".success" do
      it "creates a successful result" do
        result = WebPageFetchService::Result.success(content: "Hello")
        expect(result).to be_success
        expect(result).not_to be_failure
        expect(result.content).to eq("Hello")
        expect(result.error).to be_nil
      end
    end

    describe ".failure" do
      it "creates a failed result" do
        result = WebPageFetchService::Result.failure("Something went wrong")
        expect(result).not_to be_success
        expect(result).to be_failure
        expect(result.content).to be_nil
        expect(result.error).to eq("Something went wrong")
      end
    end
  end
end
