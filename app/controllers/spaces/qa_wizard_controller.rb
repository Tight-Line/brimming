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

      if @titles.empty?
        redirect_to space_qa_wizard_path(@space), alert: "No titles available. Please generate titles first."
      end
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
      else
        @question_body = params[:question_body] || ""
        @answer = params[:answer] || ""
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

      { success: true, titles: titles, source_data: article.id.to_s }
    end

    def generate_titles_from_rag(count)
      query = params[:query]
      chunks = retrieve_relevant_chunks(query, limit: 10)

      if chunks.empty?
        return { success: false, error: "No relevant content found in this space" }
      end

      content = chunks.map(&:content).join("\n\n---\n\n")
      prompt = build_titles_prompt(content, count)
      titles = call_llm_for_titles(prompt)

      { success: true, titles: titles, source_data: query }
    end

    def generate_titles_from_topic(count)
      topic = params[:topic_description]
      return { success: false, error: "Please provide a topic description" } if topic.blank?

      # Search KB using the topic to find relevant content for question generation
      chunks = retrieve_relevant_chunks(topic, limit: 10)

      if chunks.empty?
        return { success: false, error: "No relevant content found in the knowledge base for this topic. Try uploading articles first." }
      end

      content = chunks.map(&:content).join("\n\n---\n\n")
      prompt = build_titles_prompt(content, count, topic: topic)
      titles = call_llm_for_titles(prompt)

      { success: true, titles: titles, source_data: topic }
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

    def generate_qa_content(title, source_type, source_data)
      prompt = build_qa_content_prompt(title, source_type, source_data)

      provider = LlmProvider.default_provider
      client = LlmService::Client.new(provider)
      response = client.generate_json(prompt)

      {
        question_body: response["question_body"].to_s,
        answer: response["answer"].to_s
      }
    rescue StandardError => e
      Rails.logger.error("[QaWizard] Failed to generate content: #{e.message}")
      { question_body: "", answer: "" }
    end

    def build_qa_content_prompt(title, _source_type, _source_data)
      # Always search the KB using the question title to find relevant context
      # This ensures answers are grounded in actual KB content regardless of
      # how the question title was originally generated
      chunks = retrieve_relevant_chunks(title, limit: 10)

      if chunks.any?
        context = "RELEVANT CONTEXT FROM KNOWLEDGE BASE:\n\n#{chunks.map(&:content).join("\n\n---\n\n")}"
        grounding_instruction = "Base your answer strictly on the provided context. If the context doesn't contain enough information to fully answer the question, acknowledge what's missing."
      else
        context = "(No relevant content found in the knowledge base for this question)"
        grounding_instruction = "WARNING: No relevant content was found in the knowledge base. The answer below may need manual verification and editing."
      end

      <<~PROMPT
        Generate a detailed question body and comprehensive answer for this FAQ question.

        QUESTION TITLE: #{title}
        SPACE: #{@space.name}

        #{context}

        #{grounding_instruction}

        The question_body should:
        - Provide specific context about what the user is trying to accomplish
        - Be written from the user's perspective (first person)
        - Include relevant details that expand on the title
        - Be 50-500 characters

        The answer should:
        - Be comprehensive and directly address the question
        - Use markdown formatting (code blocks, lists, bold) where appropriate
        - Be 100-2000 characters
        - Only include information that can be verified from the provided context

        Respond with JSON only:
        {
          "question_body": "The detailed question body...",
          "answer": "The comprehensive answer..."
        }
      PROMPT
    end

    def retrieve_relevant_chunks(query, limit:)
      if query.blank?
        return Chunk.joins("INNER JOIN articles ON chunks.chunkable_type = 'Article' AND chunks.chunkable_id = articles.id")
                    .joins("INNER JOIN article_spaces ON articles.id = article_spaces.article_id")
                    .where(article_spaces: { space_id: @space.id })
                    .order(created_at: :desc)
                    .limit(limit)
      end

      if EmbeddingService.available? && defined?(Search::ChunkVectorQueryService)
        result = Search::ChunkVectorQueryService.new(
          q: query,
          space_id: @space.id,
          limit: limit,
          types: %w[Article]
        ).call
        # Return chunks from the hits
        result.hits.map(&:best_chunk).compact
      else
        Chunk.joins("INNER JOIN articles ON chunks.chunkable_type = 'Article' AND chunks.chunkable_id = articles.id")
             .joins("INNER JOIN article_spaces ON articles.id = article_spaces.article_id")
             .where(article_spaces: { space_id: @space.id })
             .where("chunks.content ILIKE ?", "%#{query}%")
             .limit(limit)
      end
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
  end
end
