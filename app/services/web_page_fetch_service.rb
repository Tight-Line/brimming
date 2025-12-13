# frozen_string_literal: true

require "net/http"
require "json"

class WebPageFetchService
  class Result
    attr_reader :content, :error

    def initialize(success:, content: nil, error: nil)
      @success = success
      @content = content
      @error = error
    end

    def success?
      @success
    end

    def failure?
      !@success
    end

    def self.success(content:)
      new(success: true, content: content)
    end

    def self.failure(error)
      new(success: false, error: error)
    end
  end

  DEFAULT_TIMEOUT = 30

  def initialize(url, provider: nil)
    @url = url
    @provider = provider || ReaderProvider.enabled_provider
  end

  def fetch
    return Result.failure("No reader provider configured") unless @provider
    return Result.failure("Invalid URL") unless valid_url?
    return Result.failure("Invalid reader provider endpoint") unless valid_provider_endpoint?

    content = fetch_from_provider
    Result.success(content: content)
  rescue Net::OpenTimeout, Net::ReadTimeout, Timeout::Error
    Result.failure("Request timed out while fetching the page")
  rescue SocketError => e
    Result.failure("Could not connect to reader service: #{e.message}")
  rescue StandardError => e
    Result.failure("Failed to fetch page: #{e.message}")
  end

  private

  def valid_url?
    uri = URI.parse(@url)
    uri.is_a?(URI::HTTP) || uri.is_a?(URI::HTTPS)
  rescue URI::InvalidURIError
    false
  end

  def valid_provider_endpoint?
    # Firecrawl uses the gem, no endpoint validation needed
    return true if @provider.provider_type == "firecrawl"

    return false if @provider.api_endpoint.blank?

    uri = URI.parse(@provider.api_endpoint)
    uri.is_a?(URI::HTTP) || uri.is_a?(URI::HTTPS)
  rescue URI::InvalidURIError
    false
  end

  def validated_endpoint
    # Returns the endpoint only after validation has passed
    # This method should only be called after valid_provider_endpoint? returns true
    @provider.api_endpoint.chomp("/")
  end

  def fetch_from_provider
    case @provider.provider_type
    when "jina"
      fetch_via_jina
    when "firecrawl"
      fetch_via_firecrawl
    else
      raise "Unsupported provider type: #{@provider.provider_type}"
    end
  end

  def fetch_via_jina
    # Jina Reader API: GET https://r.jina.ai/{url}
    # Use JSON format to get clean content without metadata cruft
    reader_url = "#{validated_endpoint}/#{@url}"

    uri = URI.parse(reader_url)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = (uri.scheme == "https")
    http.open_timeout = DEFAULT_TIMEOUT
    http.read_timeout = DEFAULT_TIMEOUT

    request = Net::HTTP::Get.new(uri.request_uri)
    request["Accept"] = "application/json"
    # Target common article content selectors to avoid navigation cruft
    request["X-Target-Selector"] = "article, main, .post-content, .article-content, .entry-content, .content"

    # Add API key if configured
    if @provider.api_key.present?
      request["Authorization"] = "Bearer #{@provider.api_key}"
    end

    response = http.request(request)

    case response.code.to_i
    when 200
      extract_content_from_json(response.body)
    when 401
      raise "Authentication failed - check your API key"
    when 403
      raise "Access forbidden - the page may be blocked"
    when 404
      raise "Page not found at the specified URL"
    when 429
      raise "Rate limit exceeded - please try again later"
    when 500..599
      raise "Reader service error (#{response.code})"
    else
      raise "Unexpected response: #{response.code} #{response.message}"
    end
  end

  def extract_content_from_json(body)
    json = JSON.parse(body.dup.force_encoding("UTF-8"))
    # Jina returns { "data": { "content": "...", "title": "...", ... } }
    content = json.dig("data", "content")
    raise "No content found in response" if content.blank?

    content
  rescue JSON::ParserError => e
    raise "Failed to parse response: #{e.message}"
  end

  def fetch_via_firecrawl
    # Use firecrawl gem for Firecrawl.dev cloud API
    Firecrawl.api_key(@provider.api_key)
    response = Firecrawl.scrape(@url, formats: [ "markdown" ], only_main_content: true)

    if response.success?
      content = response.markdown
      raise "No content found in response" if content.blank?
      content
    else
      raise "Firecrawl error: #{response.error || 'Unknown error'}"
    end
  end
end
