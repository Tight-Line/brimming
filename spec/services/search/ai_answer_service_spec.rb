# frozen_string_literal: true

require "rails_helper"

RSpec.describe Search::AiAnswerService do
  let(:space) { create(:space) }
  let(:user) { create(:user) }

  describe ".call" do
    context "when LLM is not available" do
      before do
        allow(LlmService).to receive(:available?).and_return(false)
      end

      it "returns result with nil answer" do
        result = described_class.call(query: "test")

        expect(result.answer).to be_nil
        expect(result.sources).to eq([])
        expect(result.chunks_used).to eq(0)
        expect(result.query).to eq("test")
        expect(result.from_knowledge_base).to be(false)
      end
    end

    context "when LLM is available" do
      let(:llm_provider) { create(:llm_provider, :openai, enabled: true, is_default: true) }
      let(:mock_client) { instance_double(LlmService::Client) }

      before do
        llm_provider
        allow(LlmService).to receive(:available?).and_return(true)
        allow(LlmService).to receive(:client).and_return(mock_client)
      end

      context "with blank query" do
        before do
          allow(mock_client).to receive(:generate_json).and_return({
            "answer" => "Here's a general answer to your question."
          })
        end

        it "returns general knowledge answer" do
          result = described_class.call(query: "")

          expect(result.answer).to include("general answer")
          expect(result.chunks_used).to eq(0)
          expect(result.from_knowledge_base).to be(false)
        end
      end

      context "with keyword search fallback" do
        let!(:article) { create(:article, title: "Ruby Guide", user: user, spaces: [ space ]) }
        let!(:chunk) { create(:chunk, chunkable: article, content: "Ruby is a programming language") }

        before do
          allow(EmbeddingService).to receive(:available?).and_return(false)
          allow(mock_client).to receive(:generate_json).and_return({
            "answer" => "Ruby is a programming language used for web development.",
            "sources" => [
              { "type" => "Article", "id" => article.id, "title" => "Ruby Guide", "excerpt" => "Ruby is a programming language" }
            ]
          })
        end

        it "uses ILIKE search on chunk content" do
          result = described_class.call(query: "Ruby")

          expect(result.answer).to include("Ruby")
          expect(result.chunks_used).to eq(1)
        end

        it "returns sources from LLM response" do
          result = described_class.call(query: "Ruby")

          expect(result.sources.length).to eq(1)
          expect(result.sources.first[:type]).to eq("Article")
          expect(result.sources.first[:id]).to eq(article.id)
        end

        it "marks result as from knowledge base" do
          result = described_class.call(query: "Ruby")

          expect(result.from_knowledge_base).to be(true)
        end
      end

      context "when no chunks match but LLM available" do
        before do
          allow(EmbeddingService).to receive(:available?).and_return(false)
          allow(mock_client).to receive(:generate_json).and_return({
            "answer" => "Based on my general knowledge, here's the answer."
          })
        end

        it "generates answer from general knowledge" do
          result = described_class.call(query: "something not in knowledge base")

          expect(result.answer).to include("general knowledge")
          expect(result.chunks_used).to eq(0)
          expect(result.sources).to eq([])
        end

        it "marks result as NOT from knowledge base" do
          result = described_class.call(query: "something not in knowledge base")

          expect(result.from_knowledge_base).to be(false)
        end
      end

      context "with vector search" do
        let!(:article) { create(:article, title: "Vector Article", user: user, spaces: [ space ]) }
        let!(:chunk) { create(:chunk, chunkable: article, content: "Vector search content") }
        let(:mock_vector_service) { instance_double(Search::ChunkVectorQueryService) }
        let(:hit) do
          Search::ChunkVectorQueryService::Hit.new(
            id: article.id,
            score: 0.85,
            type: "Article",
            chunkable: article,
            best_chunk: chunk
          )
        end

        before do
          allow(EmbeddingService).to receive(:available?).and_return(true)
          allow(Search::ChunkVectorQueryService).to receive(:new).and_return(mock_vector_service)
          allow(mock_vector_service).to receive(:call).and_return(
            OpenStruct.new(hits: [ hit ])
          )
          allow(mock_client).to receive(:generate_json).and_return({
            "answer" => "Answer from vector search",
            "sources" => []
          })
        end

        it "uses vector search when embeddings available" do
          result = described_class.call(query: "vector content")

          expect(Search::ChunkVectorQueryService).to have_received(:new).with(
            hash_including(q: "vector content")
          )
          expect(result.answer).to eq("Answer from vector search")
        end

        it "passes space_id to vector search when space is provided" do
          described_class.call(query: "vector content", space: space)

          expect(Search::ChunkVectorQueryService).to have_received(:new).with(
            hash_including(space_id: space.id)
          )
        end
      end

      context "when LLM returns Article source not in chunks but exists in database" do
        let!(:search_article) { create(:article, title: "Search Article", user: user, spaces: [ space ]) }
        let!(:chunk) { create(:chunk, chunkable: search_article, content: "Content that matches") }
        # This article exists in DB but wasn't in the chunks sent to the LLM
        let!(:referenced_article) { create(:article, title: "Referenced Article", user: user, spaces: [ space ]) }

        before do
          allow(EmbeddingService).to receive(:available?).and_return(false)
          # LLM returns a source with ID of referenced_article (exists in DB, not in chunks)
          allow(mock_client).to receive(:generate_json).and_return({
            "answer" => "Answer referencing different article",
            "sources" => [
              { "type" => "Article", "id" => referenced_article.id, "title" => "Referenced Article", "excerpt" => "..." }
            ]
          })
        end

        it "looks up Article slug from database when not in chunk lookup" do
          result = described_class.call(query: "Content that matches")

          expect(result.sources.first[:slug]).to eq(referenced_article.slug)
        end
      end

      context "when LLM returns Question source not in chunks but exists in database" do
        let!(:search_article) { create(:article, title: "Search Article", user: user, spaces: [ space ]) }
        let!(:chunk) { create(:chunk, chunkable: search_article, content: "Content that matches") }
        # This question exists in DB but wasn't in the chunks sent to the LLM
        let!(:referenced_question) { create(:question, title: "Referenced Question", user: user, space: space) }

        before do
          allow(EmbeddingService).to receive(:available?).and_return(false)
          # LLM returns a Question source (exists in DB, not in chunks)
          allow(mock_client).to receive(:generate_json).and_return({
            "answer" => "Answer referencing a question",
            "sources" => [
              { "type" => "Question", "id" => referenced_question.id, "title" => "Referenced Question", "excerpt" => "..." }
            ]
          })
        end

        it "looks up Question slug from database when not in chunk lookup" do
          result = described_class.call(query: "Content that matches")

          expect(result.sources.first[:slug]).to eq(referenced_question.slug)
        end
      end

      context "when LLM returns source not found anywhere (non-existent ID)" do
        let!(:article) { create(:article, title: "Matched Article", user: user, spaces: [ space ]) }
        let!(:chunk) { create(:chunk, chunkable: article, content: "Content that matches") }

        before do
          allow(EmbeddingService).to receive(:available?).and_return(false)
          # LLM returns a source with ID 99999 that doesn't exist anywhere
          allow(mock_client).to receive(:generate_json).and_return({
            "answer" => "Answer with unknown source",
            "sources" => [
              { "type" => "Article", "id" => 99999, "title" => "Unknown Article", "excerpt" => "..." }
            ]
          })
        end

        it "uses ID as fallback slug when source not found in chunks or database" do
          result = described_class.call(query: "Content that matches")

          expect(result.sources.first[:slug]).to eq("99999")
        end
      end

      context "when LLM returns source with unknown type" do
        let!(:article) { create(:article, title: "Matched Article", user: user, spaces: [ space ]) }
        let!(:chunk) { create(:chunk, chunkable: article, content: "Content that matches") }

        before do
          allow(EmbeddingService).to receive(:available?).and_return(false)
          # LLM returns a source with unknown type (neither Article nor Question)
          allow(mock_client).to receive(:generate_json).and_return({
            "answer" => "Answer with unknown type source",
            "sources" => [
              { "type" => "SomeUnknownType", "id" => 1, "title" => "Unknown Type Source", "excerpt" => "..." }
            ]
          })
        end

        it "uses ID as fallback slug when source type is unknown" do
          result = described_class.call(query: "Content that matches")

          expect(result.sources.first[:slug]).to eq("1")
        end
      end

      context "when LLM returns source that matches a chunk" do
        let!(:article) { create(:article, title: "Matched Article", user: user, spaces: [ space ]) }
        let!(:chunk) { create(:chunk, chunkable: article, content: "Content with matching source") }

        before do
          allow(EmbeddingService).to receive(:available?).and_return(false)
          # LLM returns a source with ID matching the article we have in chunks
          allow(mock_client).to receive(:generate_json).and_return({
            "answer" => "Answer with matching source",
            "sources" => [
              { "type" => "Article", "id" => article.id, "title" => "Matched Article", "excerpt" => "..." }
            ]
          })
        end

        it "uses actual article slug when source found in chunks" do
          result = described_class.call(query: "matching")

          expect(result.sources.first[:slug]).to eq(article.slug)
        end
      end

      context "when LLM doesn't return sources" do
        let!(:article) { create(:article, title: "No Sources Article", user: user, spaces: [ space ]) }
        let!(:chunk) { create(:chunk, chunkable: article, content: "Content without LLM sources") }

        before do
          allow(EmbeddingService).to receive(:available?).and_return(false)
          allow(mock_client).to receive(:generate_json).and_return({
            "answer" => "Answer without sources",
            "sources" => []
          })
        end

        it "falls back to using chunks as sources" do
          result = described_class.call(query: "without")

          expect(result.sources.length).to eq(1)
          expect(result.sources.first[:type]).to eq("Article")
          expect(result.sources.first[:title]).to eq("No Sources Article")
          expect(result.sources.first[:excerpt]).to include("Content without")
        end
      end

      context "with space filter" do
        let(:other_space) { create(:space) }
        let!(:article_in_space) { create(:article, title: "In Space", user: user, spaces: [ space ]) }
        let!(:chunk_in_space) { create(:chunk, chunkable: article_in_space, content: "Content in target space") }
        let!(:article_other) { create(:article, title: "Other Space", user: user, spaces: [ other_space ]) }
        let!(:chunk_other) { create(:chunk, chunkable: article_other, content: "Content in other space") }

        before do
          allow(EmbeddingService).to receive(:available?).and_return(false)
          allow(mock_client).to receive(:generate_json).and_return({
            "answer" => "Filtered answer",
            "sources" => []
          })
        end

        it "only retrieves chunks from the specified space" do
          result = described_class.call(query: "Content", space: space)

          # Should only find 1 chunk (from target space)
          expect(result.chunks_used).to eq(1)
          expect(result.sources.first[:title]).to eq("In Space")
        end
      end

      context "with Question chunks" do
        let!(:question) { create(:question, title: "Question Title", user: user, space: space) }
        let!(:chunk) { create(:chunk, chunkable: question, content: "Question body content") }

        before do
          allow(EmbeddingService).to receive(:available?).and_return(false)
          allow(mock_client).to receive(:generate_json).and_return({
            "answer" => "Answer from question content",
            "sources" => []
          })
        end

        it "handles Question source type" do
          result = described_class.call(query: "Question body")

          expect(result.sources.first[:type]).to eq("Question")
          expect(result.sources.first[:title]).to eq("Question Title")
        end
      end

      context "with unknown chunkable type" do
        let!(:comment) { create(:comment, user: user) }
        let!(:chunk) { create(:chunk, chunkable: comment, content: "Unknown type content") }

        before do
          allow(EmbeddingService).to receive(:available?).and_return(false)
          allow(mock_client).to receive(:generate_json).and_return({
            "answer" => "Answer from unknown type",
            "sources" => []
          })
        end

        it "handles unknown source type gracefully" do
          result = described_class.call(query: "Unknown type")

          expect(result.sources.first[:type]).to eq("Comment")
          expect(result.sources.first[:title]).to eq("Untitled")
        end
      end

      context "with custom chunk limit" do
        let!(:articles) do
          5.times.map do |i|
            article = create(:article, title: "Article #{i}", user: user, spaces: [ space ])
            create(:chunk, chunkable: article, content: "Matching content #{i}")
            article
          end
        end

        before do
          allow(EmbeddingService).to receive(:available?).and_return(false)
          allow(mock_client).to receive(:generate_json).and_return({
            "answer" => "Limited answer",
            "sources" => []
          })
        end

        it "respects the chunk limit" do
          result = described_class.call(query: "Matching content", chunk_limit: 2)

          expect(result.chunks_used).to eq(2)
        end
      end

      context "when LLM raises an error" do
        let!(:article) { create(:article, title: "Error Article", user: user, spaces: [ space ]) }
        let!(:chunk) { create(:chunk, chunkable: article, content: "Content for error test") }

        before do
          allow(EmbeddingService).to receive(:available?).and_return(false)
          allow(mock_client).to receive(:generate_json).and_raise(LlmService::Client::ApiError, "API error")
        end

        it "returns error result" do
          result = described_class.call(query: "error test")

          expect(result.answer).to be_nil
          expect(result.sources).to eq([])
        end

        it "logs the error" do
          allow(Rails.logger).to receive(:error)

          described_class.call(query: "error test")

          expect(Rails.logger).to have_received(:error).with(/AiAnswerService LLM error/)
        end
      end
    end
  end

  describe "effective_chunk_limit" do
    let(:llm_provider) { create(:llm_provider, :openai, enabled: true, is_default: true) }
    let(:mock_client) { instance_double(LlmService::Client) }

    before do
      llm_provider
      allow(LlmService).to receive(:available?).and_return(true)
      allow(LlmService).to receive(:client).and_return(mock_client)
      allow(EmbeddingService).to receive(:available?).and_return(false)
      allow(mock_client).to receive(:generate_json).and_return({
        "answer" => "Test answer",
        "sources" => []
      })
    end

    context "without space" do
      it "uses global SearchSetting.rag_chunk_limit" do
        SearchSetting.rag_chunk_limit = 15

        # Create enough chunks to test the limit
        20.times do |i|
          article = create(:article, title: "Article #{i}", user: user)
          create(:chunk, chunkable: article, content: "Limit test content #{i}")
        end

        result = described_class.call(query: "Limit test")

        expect(result.chunks_used).to eq(15)
      end
    end

    context "with space override" do
      let(:space_with_limit) { create(:space, rag_chunk_limit: 3) }

      it "uses space's effective_rag_chunk_limit" do
        10.times do |i|
          article = create(:article, title: "Space Article #{i}", user: user, spaces: [ space_with_limit ])
          create(:chunk, chunkable: article, content: "Space limit content #{i}")
        end

        result = described_class.call(query: "Space limit", space: space_with_limit)

        expect(result.chunks_used).to eq(3)
      end
    end
  end
end
