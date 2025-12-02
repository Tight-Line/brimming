# frozen_string_literal: true

require "rails_helper"

RSpec.describe Search::HybridQueryService do
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
    context "with blank query and no filters" do
      it "returns empty result" do
        result = described_class.new(q: "").call

        expect(result.hits).to be_empty
        expect(result.total).to eq(0)
        expect(result.search_mode).to eq(:none)
      end
    end

    context "with blank query but filters present" do
      let!(:question) { create(:question, space: space) }

      it "uses keyword-only search" do
        result = described_class.new(q: "", space_id: space.id).call

        expect(result.search_mode).to eq(:keyword)
        expect(result.hits).not_to be_empty
      end
    end

    context "with non-relevance sort" do
      let!(:question1) { create(:question, space: space, title: "Test question one", created_at: 1.day.ago, updated_at: 1.day.ago) }
      let!(:question2) { create(:question, space: space, title: "Test question two", created_at: 1.hour.ago, updated_at: 1.hour.ago) }

      it "uses keyword-only search for newest" do
        result = described_class.new(q: "", space_id: space.id, sort: "newest").call

        expect(result.search_mode).to eq(:keyword)
        expect(result.hits.first.id).to eq(question2.id.to_s)
      end

      it "uses keyword-only search for oldest" do
        result = described_class.new(q: "", space_id: space.id, sort: "oldest").call

        expect(result.search_mode).to eq(:keyword)
        expect(result.hits.first.id).to eq(question1.id.to_s)
      end

      it "uses keyword-only search for votes" do
        question1.update_column(:vote_score, 10)

        result = described_class.new(q: "", space_id: space.id, sort: "votes").call

        expect(result.search_mode).to eq(:keyword)
        expect(result.hits.first.id).to eq(question1.id.to_s)
      end

      it "uses keyword-only search for activity" do
        question1.update_column(:updated_at, 1.minute.ago)

        result = described_class.new(q: "", space_id: space.id, sort: "activity").call

        expect(result.search_mode).to eq(:keyword)
        expect(result.hits.first.id).to eq(question1.id.to_s)
      end
    end

    context "with valid query and embeddings available" do
      let!(:question1) do
        create(:question, space: space, user: user, title: "Ruby authentication best practices").tap do |q|
          q.update_columns(embedded_at: 1.hour.ago)
          create(:chunk, :embedded, chunkable: q, embedding_provider: provider)
        end
      end

      let!(:question2) do
        create(:question, space: space, user: user, title: "Rails security guide").tap do |q|
          q.update_columns(embedded_at: 1.hour.ago)
          create(:chunk, :embedded, chunkable: q, embedding_provider: provider)
        end
      end

      before do
        # Mock ChunkVectorQueryService to return vector search results
        mock_hits = [
          Search::ChunkVectorQueryService::Hit.new(
            id: question1.id,
            score: 0.85,
            type: "Question",
            chunkable: question1,
            best_chunk: nil
          ),
          Search::ChunkVectorQueryService::Hit.new(
            id: question2.id,
            score: 0.75,
            type: "Question",
            chunkable: question2,
            best_chunk: nil
          )
        ]
        mock_result = Search::ChunkVectorQueryService::Result.new(
          hits: mock_hits,
          total: 2,
          similarity_threshold: 0.3
        )
        allow_any_instance_of(Search::ChunkVectorQueryService).to receive(:call).and_return(mock_result)
      end

      it "uses vector search mode when results found" do
        result = described_class.new(q: "authentication security").call

        expect(result.search_mode).to eq(:vector)
      end

      it "returns vector results with scores" do
        result = described_class.new(q: "authentication security").call

        expect(result.hits).not_to be_empty
        result.hits.each do |hit|
          expect(hit.vector_score).to be_present
        end
      end

      it "includes source data for all results" do
        result = described_class.new(q: "authentication").call

        result.hits.each do |hit|
          expect(hit.source).to be_present
          expect(hit.source["question"]).to be_present
        end
      end
    end

    context "with article vector search results" do
      let!(:article) do
        create(:article, user: user, title: "Ruby security article", body: "Content about security").tap do |a|
          create(:chunk, :embedded, chunkable: a, embedding_provider: provider)
          create(:article_space, article: a, space: space)
        end
      end

      let!(:article_without_space) do
        create(:article, user: user, title: "Orphaned article", body: "No space assigned")
      end

      before do
        # Mock ChunkVectorQueryService to return article results
        mock_hits = [
          Search::ChunkVectorQueryService::Hit.new(
            id: article.id,
            score: 0.80,
            type: "Article",
            chunkable: article,
            best_chunk: nil
          )
        ]
        mock_result = Search::ChunkVectorQueryService::Result.new(
          hits: mock_hits,
          total: 1,
          similarity_threshold: 0.3
        )
        allow_any_instance_of(Search::ChunkVectorQueryService).to receive(:call).and_return(mock_result)
      end

      it "includes article source data in vector results" do
        result = described_class.new(q: "security").call

        expect(result.search_mode).to eq(:vector)
        expect(result.hits.first.source["type"]).to eq("article")
        expect(result.hits.first.source["article"]["title"]).to eq("Ruby security article")
        expect(result.hits.first.source["author"]["display_name"]).to eq(user.display_name)
        expect(result.hits.first.source["space"]["name"]).to eq(space.name)
        expect(result.hits.first.source["spaces"]).to be_an(Array)
      end

      it "handles articles without spaces" do
        # Mock to return article without space
        mock_hits = [
          Search::ChunkVectorQueryService::Hit.new(
            id: article_without_space.id,
            score: 0.75,
            type: "Article",
            chunkable: article_without_space,
            best_chunk: nil
          )
        ]
        mock_result = Search::ChunkVectorQueryService::Result.new(
          hits: mock_hits,
          total: 1,
          similarity_threshold: 0.3
        )
        allow_any_instance_of(Search::ChunkVectorQueryService).to receive(:call).and_return(mock_result)

        result = described_class.new(q: "orphaned").call

        expect(result.hits.first.source["type"]).to eq("article")
        expect(result.hits.first.source["space"]).to be_nil
        expect(result.hits.first.source["spaces"]).to eq([])
      end

      it "handles articles without user" do
        # Create an article without a user (user was deleted)
        article_no_user = create(:article, user: user, title: "No user article")
        # Simulate user being nil (as if user was deleted but article still exists)
        allow(article_no_user).to receive(:user).and_return(nil)

        mock_hits = [
          Search::ChunkVectorQueryService::Hit.new(
            id: article_no_user.id,
            score: 0.72,
            type: "Article",
            chunkable: article_no_user,
            best_chunk: nil
          )
        ]
        mock_result = Search::ChunkVectorQueryService::Result.new(
          hits: mock_hits,
          total: 1,
          similarity_threshold: 0.3
        )
        allow_any_instance_of(Search::ChunkVectorQueryService).to receive(:call).and_return(mock_result)

        result = described_class.new(q: "test").call

        expect(result.hits.first.source["type"]).to eq("article")
        expect(result.hits.first.source["author"]).to be_nil
      end

      it "handles unknown chunkable types gracefully" do
        # Create a mock for an unknown type
        unknown_chunkable = double("Unknown", class: double(name: "Unknown"), id: 999)
        mock_hits = [
          Search::ChunkVectorQueryService::Hit.new(
            id: 999,
            score: 0.70,
            type: "Unknown",
            chunkable: unknown_chunkable,
            best_chunk: nil
          )
        ]
        mock_result = Search::ChunkVectorQueryService::Result.new(
          hits: mock_hits,
          total: 1,
          similarity_threshold: 0.3
        )
        allow_any_instance_of(Search::ChunkVectorQueryService).to receive(:call).and_return(mock_result)

        result = described_class.new(q: "test").call

        expect(result.hits.first.source["type"]).to eq("Unknown")
        expect(result.hits.first.source["id"]).to eq(999)
      end
    end

    context "without embedding provider" do
      let!(:question) { create(:question, space: space, title: "Test question for keyword search") }

      before { EmbeddingProvider.delete_all }

      it "falls back to keyword-only search" do
        result = described_class.new(q: "keyword").call

        expect(result.search_mode).to eq(:keyword)
      end
    end

    context "when vector search returns no results" do
      let!(:question) { create(:question, space: space, title: "PostgreSQL keyword fallback test") }

      it "falls back to keyword search" do
        # No embeddings, vector search returns empty, falls back to keyword
        result = described_class.new(q: "PostgreSQL keyword fallback").call

        expect(result.search_mode).to eq(:keyword)
        expect(result.hits).not_to be_empty
      end
    end

    context "with filters" do
      let!(:question_in_space) { create(:question, space: space, title: "Question in target space") }
      let!(:question_other_space) { create(:question, title: "Question in other space") }

      it "filters by space_id" do
        result = described_class.new(q: "", space_id: space.id).call

        expect(result.hits.map(&:id)).to include(question_in_space.id.to_s)
        expect(result.hits.map(&:id)).not_to include(question_other_space.id.to_s)
      end

      it "filters by user_id" do
        question = create(:question, user: user, title: "User specific question")

        result = described_class.new(q: "", user_id: user.id).call

        expect(result.hits.map(&:id)).to include(question.id.to_s)
      end

      it "filters by tags" do
        tag = create(:tag, space: space, name: "ruby")
        question = create(:question, space: space, title: "Tagged question", tags: [ tag ])

        result = described_class.new(q: "", space_id: space.id, tags: [ "ruby" ]).call

        expect(result.hits.map(&:id)).to include(question.id.to_s)
      end
    end

    context "pagination" do
      before do
        25.times { |i| create(:question, space: space, title: "Question #{i}") }
      end

      it "returns paginated results" do
        result = described_class.new(q: "", space_id: space.id, page: 1, per_page: 20).call

        expect(result.page).to eq(1)
        expect(result.per_page).to eq(20)
        expect(result.hits.length).to eq(20)
      end

      it "calculates total pages correctly" do
        result = described_class.new(q: "", space_id: space.id, per_page: 20).call

        expect(result.total).to eq(25)
        expect(result.total_pages).to eq(2)
      end
    end
  end

  describe "full-text search ranking" do
    let!(:title_match) { create(:question, space: space, title: "Ruby authentication guide", body: "Some content about coding") }
    let!(:body_match) { create(:question, space: space, title: "General coding tips", body: "This covers Ruby authentication patterns") }

    it "ranks title matches higher than body matches" do
      # Ensure no embeddings so we use keyword search
      EmbeddingProvider.delete_all

      result = described_class.new(q: "Ruby authentication").call

      expect(result.search_mode).to eq(:keyword)
      # Title match should rank higher due to 'A' weight vs 'B' weight
      expect(result.hits.first.id).to eq(title_match.id.to_s)
    end
  end

  describe "error handling" do
    context "when service check fails" do
      before do
        # Make EmbeddingService.available? raise an error, which happens in the main call method
        allow(EmbeddingService).to receive(:available?).and_raise(StandardError.new("Service unavailable"))
      end

      it "returns error result from main rescue block" do
        result = described_class.new(q: "test query").call

        expect(result.search_mode).to eq(:error)
        expect(result.hits).to be_empty
      end
    end

    context "when search fails completely" do
      before do
        allow(Question).to receive(:not_deleted).and_raise(StandardError.new("Database error"))
      end

      it "returns error result" do
        result = described_class.new(q: "test").call

        expect(result.search_mode).to eq(:error)
        expect(result.hits).to be_empty
      end
    end

    context "when keyword search fails" do
      let!(:question) { create(:question, space: space, title: "Test question") }

      before do
        EmbeddingProvider.delete_all
        # First call to not_deleted succeeds for scope build, but count fails
        call_count = 0
        allow_any_instance_of(ActiveRecord::Relation).to receive(:count) do
          call_count += 1
          raise StandardError.new("Count failed") if call_count >= 1
          1
        end
      end

      it "returns error result" do
        result = described_class.new(q: "", space_id: space.id).call

        expect(result.search_mode).to eq(:error)
        expect(result.hits).to be_empty
      end
    end

    context "when vector search fails" do
      let!(:question) do
        create(:question, space: space, title: "Test question for vector").tap do |q|
          q.update_columns(embedded_at: 1.hour.ago)
          create(:chunk, :embedded, chunkable: q, embedding_provider: provider)
        end
      end

      before do
        allow_any_instance_of(Search::ChunkVectorQueryService).to receive(:call).and_raise(StandardError.new("Vector error"))
      end

      it "falls back to keyword search" do
        result = described_class.new(q: "test").call

        # Vector failed but keyword should still work
        expect(result.search_mode).to eq(:keyword)
      end
    end
  end
end
