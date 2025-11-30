# frozen_string_literal: true

require "rails_helper"

RSpec.describe Search::VectorQueryService do
  let(:space) { create(:space) }
  let(:user) { create(:user) }
  let(:provider) { create(:embedding_provider, :openai, :enabled) }
  let(:mock_embedding) { Array.new(1536) { rand(-1.0..1.0) } }

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

  describe "#call" do
    context "with blank query" do
      it "returns empty result" do
        result = described_class.new(q: "").call

        expect(result.hits).to be_empty
        expect(result.total).to eq(0)
      end

      it "returns empty for whitespace-only query" do
        result = described_class.new(q: "   ").call

        expect(result.hits).to be_empty
        expect(result.total).to eq(0)
      end
    end

    context "without embedding provider" do
      before { EmbeddingProvider.delete_all }

      it "returns empty result" do
        result = described_class.new(q: "test query").call

        expect(result.hits).to be_empty
        expect(result.total).to eq(0)
      end
    end

    context "with valid query and embedded questions" do
      let!(:question1) do
        create(:question, space: space, user: user).tap do |q|
          q.update_columns(embedding: mock_embedding, embedded_at: 1.hour.ago)
        end
      end

      let!(:question2) do
        create(:question, space: space, user: user).tap do |q|
          q.update_columns(embedding: mock_embedding, embedded_at: 1.hour.ago)
        end
      end

      let!(:question_without_embedding) do
        create(:question, space: space, user: user)
      end

      it "returns similar questions" do
        result = described_class.new(q: "test query").call

        expect(result.hits.length).to eq(2)
        expect(result.total).to eq(2)
      end

      it "excludes questions without embeddings" do
        result = described_class.new(q: "test query").call

        question_ids = result.hits.map(&:id)
        expect(question_ids).not_to include(question_without_embedding.id)
      end

      it "excludes deleted questions" do
        question1.update!(deleted_at: Time.current)

        result = described_class.new(q: "test query").call

        question_ids = result.hits.map(&:id)
        expect(question_ids).not_to include(question1.id)
      end

      it "includes similarity scores" do
        result = described_class.new(q: "test query").call

        result.hits.each do |hit|
          expect(hit.score).to be_a(Float)
          # Cosine similarity ranges from -1 to 1
          expect(hit.score).to be_between(-1, 1)
        end
      end

      it "includes question objects" do
        result = described_class.new(q: "test query").call

        result.hits.each do |hit|
          expect(hit.question).to be_a(Question)
        end
      end
    end

    context "with space filter" do
      let(:other_space) { create(:space) }

      let!(:question_in_space) do
        create(:question, space: space, user: user).tap do |q|
          q.update_columns(embedding: mock_embedding, embedded_at: 1.hour.ago)
        end
      end

      let!(:question_in_other_space) do
        create(:question, space: other_space, user: user).tap do |q|
          q.update_columns(embedding: mock_embedding, embedded_at: 1.hour.ago)
        end
      end

      it "filters by space_id" do
        result = described_class.new(q: "test", space_id: space.id).call

        question_ids = result.hits.map(&:id)
        expect(question_ids).to include(question_in_space.id)
        expect(question_ids).not_to include(question_in_other_space.id)
      end
    end

    context "with pagination" do
      before do
        5.times do
          create(:question, space: space, user: user).tap do |q|
            q.update_columns(embedding: mock_embedding, embedded_at: 1.hour.ago)
          end
        end
      end

      it "respects limit parameter" do
        result = described_class.new(q: "test", limit: 3).call

        expect(result.hits.length).to eq(3)
      end

      it "respects offset parameter" do
        all_results = described_class.new(q: "test", limit: 5).call
        offset_results = described_class.new(q: "test", limit: 3, offset: 2).call

        expect(offset_results.hits.first.id).to eq(all_results.hits[2].id)
      end

      it "enforces maximum limit" do
        result = described_class.new(q: "test", limit: 200).call

        # MAX_LIMIT is 100
        expect(Search::VectorQueryService::MAX_LIMIT).to eq(100)
      end
    end

    context "when embedding API fails" do
      before do
        stub_request(:post, "https://api.openai.com/v1/embeddings")
          .to_return(status: 500, body: "Internal Server Error")
      end

      it "returns empty result without raising" do
        result = described_class.new(q: "test query").call

        expect(result.hits).to be_empty
        expect(result.total).to eq(0)
      end
    end

    context "when API key is invalid" do
      before do
        stub_request(:post, "https://api.openai.com/v1/embeddings")
          .to_return(status: 401, body: "Invalid API key")
      end

      it "returns empty result without raising" do
        result = described_class.new(q: "test query").call

        expect(result.hits).to be_empty
        expect(result.total).to eq(0)
      end
    end

    context "with similarity threshold filtering" do
      # Create embeddings with known distances from the query embedding
      let(:query_embedding) { Array.new(1536) { 0.0 }.tap { |e| e[0] = 1.0 } }
      let(:similar_embedding) { Array.new(1536) { 0.0 }.tap { |e| e[0] = 0.9; e[1] = 0.1 } }
      let(:dissimilar_embedding) { Array.new(1536) { 0.0 }.tap { |e| e[1] = 1.0 } }

      let!(:similar_question) do
        create(:question, space: space, user: user).tap do |q|
          q.update_columns(embedding: similar_embedding, embedded_at: 1.hour.ago)
        end
      end

      let!(:dissimilar_question) do
        create(:question, space: space, user: user).tap do |q|
          q.update_columns(embedding: dissimilar_embedding, embedded_at: 1.hour.ago)
        end
      end

      before do
        stub_request(:post, "https://api.openai.com/v1/embeddings")
          .to_return(
            status: 200,
            body: {
              data: [ { index: 0, embedding: query_embedding } ]
            }.to_json,
            headers: { "Content-Type" => "application/json" }
          )
      end

      it "filters out results below the provider's similarity threshold" do
        # Provider has default threshold of 0.3 for OpenAI
        result = described_class.new(q: "test query").call

        # Only the similar question should pass the threshold
        expect(result.hits.map(&:id)).to include(similar_question.id)
        expect(result.hits.map(&:id)).not_to include(dissimilar_question.id)
      end

      it "allows custom similarity threshold to override provider setting" do
        # With threshold of 0, all results should be included
        result = described_class.new(q: "test query", similarity_threshold: 0).call

        expect(result.hits.length).to eq(2)
      end

      it "includes the similarity threshold in the result" do
        result = described_class.new(q: "test query").call

        # OpenAI text-embedding-3-small default threshold is 0.28
        expect(result.similarity_threshold).to eq(0.28)
      end

      it "uses the fallback threshold constant when no provider" do
        expect(described_class::FALLBACK_SIMILARITY_THRESHOLD).to eq(0.3)
      end

      context "with custom provider threshold" do
        before do
          provider.similarity_threshold = 0.5
          provider.save!
        end

        it "uses the provider's configured threshold" do
          result = described_class.new(q: "test query").call

          expect(result.similarity_threshold).to eq(0.5)
        end
      end
    end

    context "when embedding client raises NoProviderError" do
      before do
        allow(EmbeddingService).to receive(:available?).and_return(true)
        allow(EmbeddingService).to receive(:client).and_raise(EmbeddingService::Client::NoProviderError)
      end

      it "returns empty result" do
        result = described_class.new(q: "test query").call

        expect(result.hits).to be_empty
        expect(result.total).to eq(0)
      end
    end
  end
end
