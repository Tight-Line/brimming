# frozen_string_literal: true

require "rails_helper"

RSpec.describe EmbeddingService::Adapters::Base do
  let(:provider) { create(:embedding_provider, embedding_model: "test-model", dimensions: 1536) }

  # Create a concrete implementation for testing
  let(:test_adapter_class) do
    Class.new(described_class) do
      attr_accessor :mock_embeddings

      def generate_embeddings(texts)
        mock_embeddings || texts.map { Array.new(1536) { rand } }
      end
    end
  end

  let(:adapter) { test_adapter_class.new(provider) }

  describe "#initialize" do
    it "sets the provider" do
      expect(adapter.provider).to eq(provider)
    end

    context "without embedding model" do
      let(:provider) { build(:embedding_provider, embedding_model: nil, dimensions: 1536) }

      it "raises ConfigurationError" do
        expect { test_adapter_class.new(provider) }.to raise_error(
          EmbeddingService::Adapters::Base::ConfigurationError,
          /embedding model/i
        )
      end
    end

    context "without dimensions" do
      let(:provider) { build(:embedding_provider, embedding_model: "test", dimensions: nil) }

      it "raises ConfigurationError" do
        expect { test_adapter_class.new(provider) }.to raise_error(
          EmbeddingService::Adapters::Base::ConfigurationError,
          /dimensions/i
        )
      end
    end
  end

  describe "#embed" do
    it "returns embeddings for multiple texts" do
      result = adapter.embed([ "text 1", "text 2" ])
      expect(result).to be_an(Array)
      expect(result.length).to eq(2)
      expect(result.first).to be_an(Array)
    end

    it "handles single text as string" do
      result = adapter.embed("single text")
      expect(result).to be_an(Array)
      expect(result.length).to eq(1)
    end

    it "returns empty array for empty input" do
      expect(adapter.embed([])).to eq([])
    end
  end

  describe "#embed_one" do
    it "returns a single embedding vector" do
      adapter.mock_embeddings = [ [ 1.0, 2.0, 3.0 ] ]
      result = adapter.embed_one("test text")
      expect(result).to eq([ 1.0, 2.0, 3.0 ])
    end
  end

  describe "#truncate_text" do
    it "returns text unchanged if within limit" do
      short_text = "Hello world"
      expect(adapter.send(:truncate_text, short_text)).to eq(short_text)
    end

    it "truncates long text and adds ellipsis" do
      # Most providers have max_input_chars around 8000
      long_text = "a" * 10_000
      result = adapter.send(:truncate_text, long_text)
      expect(result.length).to be <= provider.max_input_chars
      expect(result).to end_with("...")
    end
  end

  describe "#with_retry" do
    it "retries on RateLimitError" do
      attempts = 0
      result = adapter.send(:with_retry, max_attempts: 3, base_delay: 0.01) do
        attempts += 1
        raise EmbeddingService::Adapters::Base::RateLimitError if attempts < 2
        "success"
      end

      expect(result).to eq("success")
      expect(attempts).to eq(2)
    end

    it "raises after max attempts" do
      expect {
        adapter.send(:with_retry, max_attempts: 2, base_delay: 0.01) do
          raise EmbeddingService::Adapters::Base::RateLimitError
        end
      }.to raise_error(EmbeddingService::Adapters::Base::RateLimitError)
    end
  end

  describe "#generate_embeddings" do
    let(:base_adapter) { described_class.new(provider) }

    it "raises NotImplementedError for base class" do
      expect { base_adapter.send(:generate_embeddings, [ "text" ]) }.to raise_error(NotImplementedError)
    end
  end

  describe "error classes" do
    it "defines Error as base error" do
      expect(EmbeddingService::Adapters::Base::Error.superclass).to eq(StandardError)
    end

    it "defines ConfigurationError" do
      expect(EmbeddingService::Adapters::Base::ConfigurationError.superclass).to eq(EmbeddingService::Adapters::Base::Error)
    end

    it "defines ApiError" do
      expect(EmbeddingService::Adapters::Base::ApiError.superclass).to eq(EmbeddingService::Adapters::Base::Error)
    end

    it "defines RateLimitError as subclass of ApiError" do
      expect(EmbeddingService::Adapters::Base::RateLimitError.superclass).to eq(EmbeddingService::Adapters::Base::ApiError)
    end
  end
end
