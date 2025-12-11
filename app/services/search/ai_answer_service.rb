# frozen_string_literal: true

module Search
  # Service for generating AI-powered answers using RAG (Retrieval-Augmented Generation)
  #
  # Retrieves relevant chunks from the knowledge base, sends them to an LLM along with
  # the user's query, and returns an answer with citations to the source material.
  #
  # Usage:
  #   result = Search::AiAnswerService.call(
  #     query: "How do I reset my password?",
  #     space: space  # optional - limit to specific space
  #   )
  #
  #   result.answer       # => "To reset your password..."
  #   result.sources      # => [{ type: "Article", id: 1, title: "...", excerpt: "..." }, ...]
  #   result.chunks_used  # => 5
  #
  class AiAnswerService
    RAG_PROMPT_PATH = Rails.root.join("config/prompts/ai_answer_rag.md")
    FALLBACK_PROMPT_PATH = Rails.root.join("config/prompts/ai_answer_fallback.md")

    Result = Struct.new(:answer, :sources, :chunks_used, :query, :from_knowledge_base, keyword_init: true)

    class << self
      def call(...)
        new(...).call
      end
    end

    def initialize(query:, space: nil, chunk_limit: nil)
      @query = query
      @space = space
      @chunk_limit = chunk_limit || effective_chunk_limit
    end

    def call
      return no_llm_result unless LlmService.available?

      chunks = retrieve_chunks

      if chunks.empty?
        # No knowledge base matches - use fallback (general knowledge) with warning
        response = generate_fallback_answer
        build_fallback_result(response)
      else
        # Knowledge base matches found - use RAG prompt with context
        response = generate_answer(chunks)
        build_rag_result(response, chunks)
      end
    rescue LlmService::Client::Error => e
      Rails.logger.error("AiAnswerService LLM error: #{e.message}")
      error_result(e.message)
    end

    private

    attr_reader :query, :space, :chunk_limit

    def retrieve_chunks
      return [] if query.blank?

      if EmbeddingService.available?
        vector_search
      else
        keyword_search
      end
    end

    def vector_search
      service = ChunkVectorQueryService.new(
        q: query,
        limit: chunk_limit,
        space_id: space&.id
      )
      result = service.call

      # Extract actual chunk records from the hits
      result.hits.filter_map do |hit|
        hit.best_chunk
      end
    end

    def keyword_search
      # Fallback to ILIKE search on chunk content
      scope = Chunk.includes(:chunkable)

      if space
        # Filter to chunks belonging to content in this space
        article_ids = space.articles.pluck(:id)
        question_ids = space.questions.pluck(:id)

        scope = scope.where(
          "(chunkable_type = 'Article' AND chunkable_id IN (?)) OR " \
          "(chunkable_type = 'Question' AND chunkable_id IN (?))",
          article_ids,
          question_ids
        )
      end

      scope.where("content ILIKE ?", "%#{sanitize_like(query)}%")
           .limit(chunk_limit)
           .to_a
    end

    def generate_answer(chunks)
      prompt = build_prompt(chunks)
      client = LlmService.client
      client.generate_json(prompt)
    end

    def generate_fallback_answer
      prompt = build_fallback_prompt
      client = LlmService.client
      client.generate_json(prompt)
    end

    def build_prompt(chunks)
      template = rag_prompt_template
      context = format_chunks(chunks)

      template
        .gsub("{{QUERY}}", query)
        .gsub("{{RAG_CONTEXT}}", context)
    end

    def rag_prompt_template
      @rag_prompt_template ||= File.read(RAG_PROMPT_PATH)
    end

    def fallback_prompt_template
      @fallback_prompt_template ||= File.read(FALLBACK_PROMPT_PATH)
    end

    def build_fallback_prompt
      fallback_prompt_template.gsub("{{QUERY}}", query)
    end

    def format_chunks(chunks)
      # Note: This method is only called when chunks is non-empty
      # (empty check happens before generate_answer is called)
      chunks.map.with_index(1) do |chunk, index|
        format_chunk(chunk, index)
      end.join("\n\n---\n\n")
    end

    def format_chunk(chunk, index)
      source = chunk.chunkable
      metadata = source_metadata(source)

      <<~CHUNK
        [Source #{index}]
        Type: #{metadata[:type]}
        ID: #{metadata[:id]}
        Title: #{metadata[:title]}

        #{chunk.content}
      CHUNK
    end

    def source_metadata(source)
      case source
      when Article
        { type: "Article", id: source.id, slug: source.slug, title: source.title }
      when Question
        { type: "Question", id: source.id, slug: source.slug, title: source.title }
      else
        { type: source.class.name, id: source.try(:id), slug: source.try(:slug), title: source.try(:title) || "Untitled" }
      end
    end

    def build_rag_result(response, chunks)
      sources = extract_sources(response, chunks)

      Result.new(
        answer: response["answer"] || "",
        sources: sources,
        chunks_used: chunks.size,
        query: query,
        from_knowledge_base: true
      )
    end

    def build_fallback_result(response)
      Result.new(
        answer: response["answer"] || "",
        sources: [],
        chunks_used: 0,
        query: query,
        from_knowledge_base: false
      )
    end

    def extract_sources(response, chunks)
      # Prefer sources from LLM response if provided, but enrich with slugs from chunks
      if response["sources"].is_a?(Array) && response["sources"].any?
        # Build a lookup of chunk sources by ID for slug retrieval
        chunk_lookup = chunks.each_with_object({}) do |chunk, hash|
          source = chunk.chunkable
          hash[[ source.class.name, source.id ]] = source
        end

        response["sources"].map.with_index(1) do |src, index|
          # Try to find the actual source record to get the slug
          source_record = chunk_lookup[[ src["type"], src["id"] ]]

          # If not in chunks, try database lookup (LLM might reference sources we didn't send)
          if source_record.nil? && src["id"].present?
            source_record = find_source_by_type_and_id(src["type"], src["id"])
          end

          {
            number: src["number"] || index,
            type: src["type"],
            id: src["id"],
            slug: source_record&.slug || src["id"].to_s,
            title: src["title"],
            excerpt: src["excerpt"]
          }
        end
      else
        # Fall back to chunks as sources
        chunks.map.with_index(1) do |chunk, index|
          source = chunk.chunkable
          meta = source_metadata(source)
          {
            number: index,
            type: meta[:type],
            id: meta[:id],
            slug: meta[:slug],
            title: meta[:title],
            excerpt: chunk.content.truncate(200)
          }
        end
      end
    end

    def no_llm_result
      Result.new(
        answer: nil,
        sources: [],
        chunks_used: 0,
        query: query,
        from_knowledge_base: false
      )
    end

    def error_result(message)
      Result.new(
        answer: nil,
        sources: [],
        chunks_used: 0,
        query: query,
        from_knowledge_base: false
      )
    end

    def effective_chunk_limit
      if space
        space.effective_rag_chunk_limit
      else
        SearchSetting.rag_chunk_limit
      end
    end

    def sanitize_like(str)
      str.gsub(/[%_]/) { |m| "\\#{m}" }
    end

    # Look up source record from database by type and ID
    # Returns nil if type is unknown or record not found
    def find_source_by_type_and_id(type, id)
      case type
      when "Article"
        Article.find_by(id: id)
      when "Question"
        Question.find_by(id: id)
      end
    end
  end
end
