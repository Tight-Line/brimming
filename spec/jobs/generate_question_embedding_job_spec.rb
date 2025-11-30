# frozen_string_literal: true

require "rails_helper"

RSpec.describe GenerateQuestionEmbeddingJob do
  let(:space) { create(:space) }
  let(:user) { create(:user) }
  let(:question) { create(:question, space: space, user: user) }
  let(:provider) { create(:embedding_provider, :openai, :enabled) }
  let(:mock_embedding) { Array.new(1536) { rand } }

  before do
    provider

    stub_request(:post, "https://api.openai.com/v1/embeddings")
      .to_return(
        status: 200,
        body: {
          data: [ { index: 0, embedding: mock_embedding } ]
        }.to_json,
        headers: { "Content-Type" => "application/json" }
      )
  end

  describe "#perform" do
    it "generates and saves an embedding for the question" do
      expect(question.embedding).to be_nil
      expect(question.embedded_at).to be_nil
      expect(question.embedding_provider_id).to be_nil

      described_class.new.perform(question)

      question.reload
      expect(question.embedding).to be_present
      expect(question.embedded_at).to be_present
      expect(question.embedding_provider_id).to eq(provider.id)
    end

    it "skips if question already has an embedding from the current provider" do
      question.update_columns(
        embedding: mock_embedding,
        embedded_at: 1.hour.ago,
        embedding_provider_id: provider.id
      )

      expect(EmbeddingService).not_to receive(:client)

      described_class.new.perform(question)
    end

    it "re-embeds if question has embedding from a different provider" do
      other_provider = create(:embedding_provider, :cohere)
      question.update_columns(
        embedding: mock_embedding,
        embedded_at: 1.hour.ago,
        embedding_provider_id: other_provider.id
      )

      described_class.new.perform(question)

      question.reload
      expect(question.embedding_provider_id).to eq(provider.id)
    end

    it "regenerates embedding when force is true" do
      question.update_columns(
        embedding: mock_embedding,
        embedded_at: 1.hour.ago,
        embedding_provider_id: provider.id
      )
      old_embedded_at = question.embedded_at

      described_class.new.perform(question, force: true)

      question.reload
      expect(question.embedded_at).to be > old_embedded_at
    end

    it "skips deleted questions" do
      question.update!(deleted_at: Time.current)

      expect(EmbeddingService).not_to receive(:client)

      described_class.new.perform(question)
    end

    context "when no embedding provider is configured" do
      before do
        EmbeddingProvider.delete_all
      end

      it "skips without error" do
        expect { described_class.new.perform(question) }.not_to raise_error
        expect(question.reload.embedding).to be_nil
      end
    end

    context "when API returns an error" do
      before do
        stub_request(:post, "https://api.openai.com/v1/embeddings")
          .to_return(status: 500, body: "Internal Server Error")
      end

      it "raises ApiError for retry" do
        expect {
          described_class.new.perform(question)
        }.to raise_error(EmbeddingService::Adapters::Base::ApiError)
      end
    end

    context "when API key is invalid" do
      before do
        stub_request(:post, "https://api.openai.com/v1/embeddings")
          .to_return(status: 401, body: "Invalid API key")
      end

      it "logs error and does not retry" do
        expect(Rails.logger).to receive(:error).with(/Configuration error/)

        described_class.new.perform(question)

        expect(question.reload.embedding).to be_nil
      end
    end
  end

  describe "queue configuration" do
    it "uses the embeddings queue" do
      expect(described_class.new.queue_name).to eq("embeddings")
    end
  end
end
