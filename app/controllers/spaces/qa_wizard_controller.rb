# frozen_string_literal: true

module Spaces
  class QaWizardController < ApplicationController
    before_action :authenticate_user!
    before_action :set_space
    before_action :authorize_moderator
    before_action :ensure_llm_available, except: [ :show, :articles ]

    # GET /spaces/:space_id/qa_wizard
    # Step 1: Choose source and generate question titles
    def show
      @articles = @space.articles.order(:title)
      @questions_count = @space.questions.not_deleted.count
      @has_knowledge_base = @articles.any? || @questions_count > 0
      @llm_available = LlmService.available?
    end

    # POST /spaces/:space_id/qa_wizard/generate_titles
    # Generate a list of question titles from the selected source
    def generate_titles
      source_type = params[:source_type]
      count = (params[:count] || 5).to_i.clamp(1, 20)

      result = case source_type
      when "article"
        generate_titles_from_article(count)
      when "rag"
        generate_titles_from_rag(count)
      when "topic"
        generate_titles_from_topic(count)
      else
        { success: false, error: "Invalid source type" }
      end

      if result[:success]
        # Store in session and redirect (Turbo-compatible)
        session[:qa_wizard_titles] = result[:titles]
        session[:qa_wizard_source_type] = source_type
        session[:qa_wizard_source_data] = result[:source_data]
        session[:qa_wizard_search_query] = result[:search_query]
        redirect_to select_title_space_qa_wizard_path(@space)
      else
        redirect_to space_qa_wizard_path(@space), alert: result[:error]
      end
    end

    # GET /spaces/:space_id/qa_wizard/select_title
    # Step 2: Select from generated titles
    def select_title
      @titles = session.delete(:qa_wizard_titles) || []
      @source_type = session.delete(:qa_wizard_source_type)
      @source_data = session.delete(:qa_wizard_source_data)
      search_query = session.delete(:qa_wizard_search_query)

      if @titles.empty?
        redirect_to space_qa_wizard_path(@space), alert: "No titles available. Please generate titles first."
        return
      end

      # Find similar existing questions if feature is enabled
      @similar_questions = find_similar_questions(search_query)
    end

    # GET /spaces/:space_id/qa_wizard/edit
    # Step 2: Edit the selected question title, body, and answer
    def edit
      @question_title = params[:title]
      @source_type = params[:source_type]
      @source_data = params[:source_data]

      # Generate initial question body and answer based on the title
      if params[:generate_content] == "true"
        content = generate_qa_content(@question_title, @source_type, @source_data)
        @question_body = content[:question_body]
        @answer = content[:answer]
        @sources = content[:sources] || []
      else
        @question_body = params[:question_body] || ""
        @answer = params[:answer] || ""
        @sources = parse_sources_param(params[:sources])
      end
    end

    # POST /spaces/:space_id/qa_wizard/submit
    # Create the question and answer
    def submit
      @question_title = params[:question_title]
      @question_body = params[:question_body]
      @answer_text = params[:answer]

      if @question_title.blank? || @question_body.blank? || @answer_text.blank?
        flash.now[:alert] = "All fields are required"
        render :edit
        return
      end

      robot = User.robot
      unless robot
        redirect_to space_qa_wizard_path(@space), alert: "System robot user not configured"
        return
      end

      ActiveRecord::Base.transaction do
        @question = Question.create!(
          user: robot,
          sponsored_by: current_user,
          space: @space,
          title: @question_title,
          body: @question_body
        )

        @answer = Answer.create!(
          user: robot,
          sponsored_by: current_user,
          question: @question,
          body: @answer_text
        )

        # Mark as solved (official FAQ)
        @answer.mark_as_correct!
      end

      redirect_to question_path(@question), notice: "FAQ question created successfully!"
    rescue ActiveRecord::RecordInvalid => e
      flash.now[:alert] = "Failed to create question: #{e.message}"
      render :edit
    end

    # GET /spaces/:space_id/qa_wizard/articles
    # JSON endpoint for article list
    def articles
      articles = @space.articles.order(:title).select(:id, :title)
      render json: articles.map { |a| { id: a.id, title: a.title } }
    end

    private

    def set_space
      @space = Space.find_by!(slug: params[:space_id])
    end

    def authorize_moderator
      unless current_user.can_moderate?(@space)
        redirect_to space_path(@space), alert: "You must be a moderator to use the Q&A Wizard"
      end
    end

    def ensure_llm_available
      return if LlmService.available?

      redirect_to space_qa_wizard_path(@space), alert: "No LLM provider configured. Please contact an administrator."
    end

    def generate_titles_from_article(count)
      article = Article.find_by(id: params[:article_id])
      return { success: false, error: "Article not found" } unless article

      # Use the article's chunks for better coverage of long content
      content = article_chunks_content(article)
      prompt = build_titles_prompt(content, count, article_title: article.title)
      titles = call_llm_for_titles(prompt)

      { success: true, titles: titles, source_data: article.id.to_s, search_query: article.title }
    end

    def generate_titles_from_rag(count)
      query = params[:query]
      chunks = retrieve_relevant_chunks(query, limit: @space.effective_rag_chunk_limit)

      if chunks.empty?
        return { success: false, error: "No relevant content found in this space" }
      end

      content = chunks.map(&:content).join("\n\n---\n\n")
      prompt = build_titles_prompt(content, count)
      titles = call_llm_for_titles(prompt)

      { success: true, titles: titles, source_data: query, search_query: query }
    end

    def generate_titles_from_topic(count)
      topic = params[:topic_description]
      return { success: false, error: "Please provide a topic description" } if topic.blank?

      # Search KB using the topic to find relevant content for question generation
      chunks = retrieve_relevant_chunks(topic, limit: @space.effective_rag_chunk_limit)

      if chunks.empty?
        return { success: false, error: "No relevant content found in the knowledge base for this topic. Try uploading articles first." }
      end

      content = chunks.map(&:content).join("\n\n---\n\n")
      prompt = build_titles_prompt(content, count, topic: topic)
      titles = call_llm_for_titles(prompt)

      { success: true, titles: titles, source_data: topic, search_query: topic }
    end

    def build_titles_prompt(content, count, article_title: nil, topic: nil)
      existing = @space.questions.not_deleted.pluck(:title)
      existing_section = existing.any? ? "\n\nEXISTING QUESTIONS (avoid duplicates):\n#{existing.map { |q| "- #{q}" }.join("\n")}" : ""

      source_hint = if article_title
        "Content is from article: #{article_title}"
      elsif topic
        "Content relates to topic: #{topic}"
      else
        ""
      end

      <<~PROMPT
        Based on the following content, generate exactly #{count} question titles that users might ask.
        Each question should be natural-sounding, like a real user would ask it.
        #{source_hint}
        #{existing_section}

        CONTENT:
        #{content}

        Respond with a JSON array of strings, each being a question title (10-200 characters).
        Example: ["How do I reset my password?", "What are the system requirements?"]

        JSON array only, no other text:
      PROMPT
    end

    def call_llm_for_titles(prompt)
      provider = LlmProvider.default_provider
      client = LlmService::Client.new(provider)
      response = client.generate_json(prompt)

      # Response should be an array of strings
      Array(response).map(&:to_s).first(20)
    rescue StandardError => e
      Rails.logger.error("[QaWizard] Failed to generate titles: #{e.message}")
      []
    end

    def generate_qa_content(title, _source_type, _source_data)
      # Always search the KB using the question title to find relevant context
      # This ensures answers are grounded in actual KB content regardless of
      # how the question title was originally generated
      chunks = retrieve_relevant_chunks(title, limit: @space.effective_rag_chunk_limit)

      # Use the prompt service for template and interpolation
      prompt_service = QaWizardPromptService.new(@space)
      prompt = prompt_service.build_content_prompt(title: title, chunks: chunks)

      provider = LlmProvider.default_provider
      client = LlmService::Client.new(provider)
      response = client.generate_json(prompt)

      # Parse response and extract sources for attribution
      parse_qa_response(response, chunks)
    rescue StandardError => e
      Rails.logger.error("[QaWizard] Failed to generate content: #{e.message}")
      { question_body: "", answer: "", sources: [] }
    end

    def parse_qa_response(response, chunks)
      result = {
        question_body: response["question_body"].to_s,
        answer: response["answer"].to_s,
        sources: []
      }

      # Parse sources from LLM response if present
      if response["sources"].is_a?(Array)
        result[:sources] = response["sources"].map do |source|
          {
            type: source["type"].to_s,
            id: source["id"].to_i,
            title: source["title"].to_s,
            excerpt: source["excerpt"].to_s
          }
        end
      elsif chunks.any?
        # Fallback: use the chunks we provided as sources
        result[:sources] = chunks.map do |chunk|
          source = chunk.chunkable
          {
            type: source.class.name,
            id: source.id,
            title: source.try(:title) || "Untitled",
            excerpt: chunk.content.truncate(200)
          }
        end.uniq { |s| [ s[:type], s[:id] ] }
      end

      result
    end

    def retrieve_relevant_chunks(query, limit:)
      if query.blank?
        return retrieve_recent_chunks_without_query(limit)
      end

      if EmbeddingService.available? && defined?(Search::ChunkVectorQueryService)
        # Search both Articles and Questions in the knowledge base
        result = Search::ChunkVectorQueryService.new(
          q: query,
          space_id: @space.id,
          limit: limit
        ).call
        # Return chunks from the hits
        result.hits.map(&:best_chunk).compact
      else
        retrieve_chunks_by_keyword(query, limit)
      end
    end

    # Fallback when no query provided: get recent chunks from the space
    def retrieve_recent_chunks_without_query(limit)
      article_chunks = Chunk
        .joins("INNER JOIN articles ON chunks.chunkable_type = 'Article' AND chunks.chunkable_id = articles.id")
        .joins("INNER JOIN article_spaces ON articles.id = article_spaces.article_id")
        .where(article_spaces: { space_id: @space.id })

      question_chunks = Chunk
        .joins("INNER JOIN questions ON chunks.chunkable_type = 'Question' AND chunks.chunkable_id = questions.id")
        .where(questions: { space_id: @space.id })

      Chunk.from("(#{article_chunks.to_sql} UNION #{question_chunks.to_sql}) AS chunks")
           .order(created_at: :desc)
           .limit(limit)
    end

    # Fallback keyword search when embeddings unavailable
    def retrieve_chunks_by_keyword(query, limit)
      sanitized_query = "%#{ActiveRecord::Base.sanitize_sql_like(query)}%"

      article_chunks = Chunk
        .joins("INNER JOIN articles ON chunks.chunkable_type = 'Article' AND chunks.chunkable_id = articles.id")
        .joins("INNER JOIN article_spaces ON articles.id = article_spaces.article_id")
        .where(article_spaces: { space_id: @space.id })
        .where("chunks.content ILIKE ?", sanitized_query)

      question_chunks = Chunk
        .joins("INNER JOIN questions ON chunks.chunkable_type = 'Question' AND chunks.chunkable_id = questions.id")
        .where(questions: { space_id: @space.id })
        .where("chunks.content ILIKE ?", sanitized_query)

      Chunk.from("(#{article_chunks.to_sql} UNION #{question_chunks.to_sql}) AS chunks")
           .limit(limit)
    end

    # Get all chunks for a specific article, ordered by chunk_index
    def article_chunks_content(article)
      chunks = article.chunks.order(:chunk_index)
      if chunks.any?
        chunks.map(&:content).join("\n\n")
      else
        # Fallback to body if no chunks exist (article not yet embedded)
        article.body.presence || ""
      end
    end

    # Parse sources from params (JSON string)
    def parse_sources_param(sources_param)
      return [] if sources_param.blank?

      JSON.parse(sources_param)
    rescue JSON::ParserError
      []
    end

    # Find similar existing questions based on the search query
    # Returns questions with their solved status for display in the UI
    def find_similar_questions(query)
      limit = @space.effective_similar_questions_limit
      return [] if limit.zero?

      if EmbeddingService.available? && defined?(Search::ChunkVectorQueryService)
        # Use vector search to find semantically similar questions
        result = Search::ChunkVectorQueryService.new(
          q: query,
          space_id: @space.id,
          limit: limit,
          types: %w[Question]
        ).call

        result.hits.map do |hit|
          question = hit.chunkable
          {
            id: question.id,
            title: question.title,
            slug: question.slug,
            solved: question.answers.exists?(is_correct: true),
            score: hit.score,
            answers_count: question.answers.count
          }
        end
      else
        # Fallback to keyword search
        @space.questions
              .not_deleted
              .where("title ILIKE ? OR body ILIKE ?",
                     "%#{ActiveRecord::Base.sanitize_sql_like(query)}%",
                     "%#{ActiveRecord::Base.sanitize_sql_like(query)}%")
              .limit(limit)
              .map do |question|
                {
                  id: question.id,
                  title: question.title,
                  slug: question.slug,
                  solved: question.answers.exists?(is_correct: true),
                  score: nil,
                  answers_count: question.answers.count
                }
              end
      end
    rescue StandardError => e
      Rails.logger.error("[QaWizard] Error finding similar questions: #{e.message}")
      []
    end
  end
end
