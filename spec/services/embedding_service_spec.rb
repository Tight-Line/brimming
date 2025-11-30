# frozen_string_literal: true

require "rails_helper"

RSpec.describe EmbeddingService do
  let(:provider) { create(:embedding_provider, :openai, :enabled) }

  describe ".available?" do
    context "when an enabled provider exists" do
      before { provider }

      it "returns true" do
        expect(described_class.available?).to be true
      end
    end

    context "when no enabled provider exists" do
      it "returns false" do
        expect(described_class.available?).to be false
      end
    end
  end

  describe ".current_provider" do
    context "when an enabled provider exists" do
      before { provider }

      it "returns the enabled provider" do
        expect(described_class.current_provider).to eq(provider)
      end
    end

    context "when no enabled provider exists" do
      it "returns nil" do
        expect(described_class.current_provider).to be_nil
      end
    end
  end

  describe ".client" do
    before { provider }

    it "returns a Client instance" do
      expect(described_class.client).to be_a(EmbeddingService::Client)
    end

    it "accepts a specific provider" do
      client = described_class.client(provider)
      expect(client.provider).to eq(provider)
    end
  end

  describe ".prepare_question_text" do
    let(:space) { create(:space) }
    let(:user) { create(:user) }
    let(:question) { create(:question, title: "How do I use Ruby?", body: "I want to learn Ruby basics.", space: space, user: user) }

    context "with question only" do
      it "includes the question title and body" do
        text = described_class.prepare_question_text(question)
        expect(text).to include("Question: How do I use Ruby?")
        expect(text).to include("I want to learn Ruby basics.")
      end
    end

    context "with an accepted answer" do
      let!(:accepted_answer) { create(:answer, question: question, body: "Ruby is a dynamic language.", is_correct: true, user: user) }
      let!(:other_answer) { create(:answer, question: question, body: "Some other answer.", vote_score: 100, user: user) }

      it "includes the accepted answer" do
        text = described_class.prepare_question_text(question)
        expect(text).to include("Best Answer: Ruby is a dynamic language.")
        expect(text).not_to include("Some other answer.")
      end
    end

    context "with no accepted answer but has answers" do
      let!(:top_answer) { create(:answer, question: question, body: "Top voted answer.", vote_score: 50, user: user) }
      let!(:low_answer) { create(:answer, question: question, body: "Low voted answer.", vote_score: 5, user: user) }

      it "includes the highest voted answer" do
        text = described_class.prepare_question_text(question)
        expect(text).to include("Best Answer: Top voted answer.")
        expect(text).not_to include("Low voted answer.")
      end
    end

    context "with no answers" do
      it "only includes the question" do
        text = described_class.prepare_question_text(question)
        expect(text).not_to include("Best Answer:")
      end
    end
  end
end

RSpec.describe EmbeddingService::Client do
  let(:provider) { create(:embedding_provider, :openai, :enabled) }

  describe "#initialize" do
    context "with a provider argument" do
      let(:specific_provider) { create(:embedding_provider, :cohere) }

      it "uses the specified provider" do
        service = described_class.new(specific_provider)
        expect(service.provider).to eq(specific_provider)
      end
    end

    context "without a provider argument" do
      before { provider }

      it "uses the default enabled provider" do
        service = described_class.new
        expect(service.provider).to eq(provider)
      end
    end

    context "when no provider is available" do
      it "raises NoProviderError" do
        expect { described_class.new }.to raise_error(EmbeddingService::Client::NoProviderError)
      end
    end

    context "with an unknown provider type" do
      let(:unknown_provider) { build(:embedding_provider, provider_type: "openai") }

      before do
        # Temporarily modify the ADAPTER_MAP to simulate unknown provider
        stub_const("EmbeddingService::Client::ADAPTER_MAP", {})
      end

      it "raises an Error" do
        expect { described_class.new(unknown_provider) }.to raise_error(EmbeddingService::Client::Error, /Unknown provider type/)
      end
    end

    context "when adapter class does not exist" do
      let(:bad_provider) { build(:embedding_provider, provider_type: "openai") }

      before do
        # Map to a class that doesn't exist
        stub_const("EmbeddingService::Client::ADAPTER_MAP", { "openai" => "EmbeddingService::Adapters::NonExistent" })
      end

      it "raises an Error about adapter not implemented" do
        expect { described_class.new(bad_provider) }.to raise_error(EmbeddingService::Client::Error, /Adapter not implemented/)
      end
    end
  end

  describe "#embed" do
    let(:mock_embedding) { Array.new(1536) { rand } }

    before do
      provider
      stub_request(:post, "https://api.openai.com/v1/embeddings")
        .to_return(
          status: 200,
          body: { data: [ { index: 0, embedding: mock_embedding } ] }.to_json
        )
    end

    it "delegates to the adapter" do
      service = described_class.new(provider)
      result = service.embed([ "test text" ])
      expect(result).to be_an(Array)
      expect(result.first.length).to eq(1536)
    end
  end

  describe "#dimensions" do
    before { provider }

    it "returns the provider dimensions" do
      service = described_class.new(provider)
      expect(service.dimensions).to eq(1536)
    end
  end
end
