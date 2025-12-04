# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Spaces::QaWizard" do
  let(:admin) { create(:user, :admin) }
  let(:moderator) { create(:user) }
  let(:user) { create(:user) }
  let(:space) { create(:space) }
  let!(:llm_provider) { create(:llm_provider, :openai, :default) }
  let!(:robot) { create(:user, role: :system, username: "helpful_robot", email: "robot@system.local") }

  before do
    space.add_moderator(moderator)
  end

  describe "GET /spaces/:space_id/qa_wizard" do
    context "when not logged in" do
      it "redirects to login" do
        get space_qa_wizard_path(space)
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "when logged in as regular user" do
      before { sign_in user }

      it "redirects with error" do
        get space_qa_wizard_path(space)
        expect(response).to redirect_to(space_path(space))
        expect(flash[:alert]).to include("moderator")
      end
    end

    context "when logged in as moderator" do
      before { sign_in moderator }

      it "returns success" do
        get space_qa_wizard_path(space)
        expect(response).to have_http_status(:success)
      end

      it "shows the wizard form" do
        get space_qa_wizard_path(space)
        expect(response.body).to include("Q&amp;A Wizard")
        expect(response.body).to include(space.name)
      end

      context "when space has no articles" do
        it "shows empty hint for article source" do
          get space_qa_wizard_path(space)
          expect(response.body).to include("No articles in this space yet")
          expect(response.body).to include("Create an article")
        end

        it "disables article radio button" do
          get space_qa_wizard_path(space)
          expect(response.body).to include('source-option-disabled')
        end

        it "defaults to topic source" do
          get space_qa_wizard_path(space)
          expect(response.body).to match(/source_type_topic[^>]*checked/)
        end
      end

      context "when space has no knowledge base content" do
        it "hides knowledge base option" do
          get space_qa_wizard_path(space)
          expect(response.body).not_to include("From Knowledge Base")
        end
      end

      context "when space has articles" do
        let!(:article) { create(:article, spaces: [ space ]) }

        it "shows article dropdown" do
          get space_qa_wizard_path(space)
          expect(response.body).to include(article.title)
          expect(response.body).not_to include("No articles in this space yet")
        end

        it "shows knowledge base option" do
          get space_qa_wizard_path(space)
          expect(response.body).to include("From Knowledge Base")
        end

        it "defaults to article source" do
          get space_qa_wizard_path(space)
          expect(response.body).to match(/source_type_article[^>]*checked/)
        end
      end

      context "when space has questions but no articles" do
        let!(:question) { create(:question, space: space) }

        it "shows knowledge base option" do
          get space_qa_wizard_path(space)
          expect(response.body).to include("From Knowledge Base")
        end

        it "still shows empty hint for article source" do
          get space_qa_wizard_path(space)
          expect(response.body).to include("No articles in this space yet")
        end
      end
    end

    context "when logged in as admin" do
      before { sign_in admin }

      it "returns success" do
        get space_qa_wizard_path(space)
        expect(response).to have_http_status(:success)
      end
    end

    context "when no LLM provider configured" do
      before do
        sign_in moderator
        LlmProvider.delete_all
      end

      it "still shows the page with warning" do
        get space_qa_wizard_path(space)
        expect(response).to have_http_status(:success)
        expect(response.body).to include("LLM Provider Required")
      end
    end
  end

  describe "POST /spaces/:space_id/qa_wizard/generate_titles" do
    let(:mock_titles) { [ "How do I reset my password?", "What are the system requirements?" ] }
    let(:mock_context) { instance_double("RubyLLM::Context") }
    let(:mock_chat) { instance_double(RubyLLM::Chat) }

    before do
      sign_in moderator
      allow(RubyLLM).to receive(:context).and_return(mock_context)
      allow(mock_context).to receive(:chat).and_return(mock_chat)
      allow(mock_chat).to receive(:ask).and_return(double(content: mock_titles.to_json))
    end

    context "with topic source" do
      # Topic source now requires KB content to exist
      let!(:article) { create(:article, spaces: [ space ]) }
      let!(:chunk) { create(:chunk, chunkable: article, content: "User authentication content") }

      it "generates titles and redirects to selection page" do
        post generate_titles_space_qa_wizard_path(space), params: {
          source_type: "topic",
          topic_description: "User authentication",
          count: 2
        }

        expect(response).to redirect_to(select_title_space_qa_wizard_path(space))
        follow_redirect!
        expect(response).to have_http_status(:success)
        expect(response.body).to include("Select a Question")
        expect(response.body).to include("How do I reset my password?")
      end

      it "requires topic description" do
        post generate_titles_space_qa_wizard_path(space), params: {
          source_type: "topic",
          topic_description: "",
          count: 2
        }

        expect(response).to redirect_to(space_qa_wizard_path(space))
        expect(flash[:alert]).to include("topic description")
      end

      it "returns error when no KB content found for topic" do
        # Remove the chunk so KB is empty
        chunk.destroy

        post generate_titles_space_qa_wizard_path(space), params: {
          source_type: "topic",
          topic_description: "completely unrelated topic",
          count: 2
        }

        expect(response).to redirect_to(space_qa_wizard_path(space))
        expect(flash[:alert]).to include("No relevant content found")
      end
    end

    context "with article source" do
      let!(:article) { create(:article, spaces: [ space ], body: "Article content here") }

      it "generates titles from article body when no chunks exist" do
        post generate_titles_space_qa_wizard_path(space), params: {
          source_type: "article",
          article_id: article.id,
          count: 2
        }

        expect(response).to redirect_to(select_title_space_qa_wizard_path(space))
        follow_redirect!
        expect(response).to have_http_status(:success)
        expect(response.body).to include("Select a Question")
      end

      it "handles missing article" do
        post generate_titles_space_qa_wizard_path(space), params: {
          source_type: "article",
          article_id: 99999,
          count: 2
        }

        expect(response).to redirect_to(space_qa_wizard_path(space))
        expect(flash[:alert]).to include("not found")
      end

      context "with existing questions in space" do
        before do
          create(:question, space: space, title: "Existing question in space")
        end

        it "includes existing questions in the prompt context" do
          post generate_titles_space_qa_wizard_path(space), params: {
            source_type: "article",
            article_id: article.id,
            count: 2
          }

          expect(response).to redirect_to(select_title_space_qa_wizard_path(space))
        end
      end

      context "when article has chunks" do
        let!(:chunk1) { create(:chunk, chunkable: article, chunk_index: 0, content: "First chunk content") }
        let!(:chunk2) { create(:chunk, chunkable: article, chunk_index: 1, content: "Second chunk content") }

        it "generates titles from article chunks instead of body" do
          post generate_titles_space_qa_wizard_path(space), params: {
            source_type: "article",
            article_id: article.id,
            count: 2
          }

          expect(response).to redirect_to(select_title_space_qa_wizard_path(space))
        end
      end
    end

    context "with rag source" do
      let!(:article) { create(:article, spaces: [ space ]) }
      let!(:chunk) { create(:chunk, chunkable: article, content: "Some content about features") }

      it "generates titles from RAG" do
        post generate_titles_space_qa_wizard_path(space), params: {
          source_type: "rag",
          query: "features",
          count: 2
        }

        expect(response).to redirect_to(select_title_space_qa_wizard_path(space))
        follow_redirect!
        expect(response).to have_http_status(:success)
        expect(response.body).to include("Select a Question")
      end
    end

    context "with invalid source type" do
      it "redirects with error" do
        post generate_titles_space_qa_wizard_path(space), params: {
          source_type: "invalid",
          count: 2
        }

        expect(response).to redirect_to(space_qa_wizard_path(space))
        expect(flash[:alert]).to include("Invalid source type")
      end
    end

    context "when not a moderator" do
      before { sign_in user }

      it "redirects with error" do
        post generate_titles_space_qa_wizard_path(space), params: {
          source_type: "topic",
          topic_description: "Test",
          count: 2
        }

        expect(response).to redirect_to(space_path(space))
      end
    end
  end

  describe "GET /spaces/:space_id/qa_wizard/edit" do
    let(:mock_content) do
      {
        "question_body" => "I need help with this feature.",
        "answer" => "Here is how you do it."
      }
    end
    let(:mock_context) { instance_double("RubyLLM::Context") }
    let(:mock_chat) { instance_double(RubyLLM::Chat) }

    before do
      sign_in moderator
      allow(RubyLLM).to receive(:context).and_return(mock_context)
      allow(mock_context).to receive(:chat).and_return(mock_chat)
      allow(mock_chat).to receive(:ask).and_return(double(content: mock_content.to_json))
    end

    it "shows the edit form" do
      get edit_space_qa_wizard_path(space), params: {
        title: "How do I reset my password?",
        source_type: "topic",
        source_data: "passwords"
      }

      expect(response).to have_http_status(:success)
      expect(response.body).to include("Edit FAQ Entry")
      expect(response.body).to include("How do I reset my password?")
    end

    it "generates content when requested" do
      get edit_space_qa_wizard_path(space), params: {
        title: "How do I reset my password?",
        source_type: "topic",
        source_data: "passwords",
        generate_content: "true"
      }

      expect(response).to have_http_status(:success)
      expect(response.body).to include("I need help with this feature")
    end
  end

  describe "POST /spaces/:space_id/qa_wizard/submit" do
    before { sign_in moderator }

    it "creates a question and answer" do
      expect {
        post submit_space_qa_wizard_path(space), params: {
          question_title: "How do I reset my password?",
          question_body: "I've forgotten my password and need to regain access to my account.",
          answer: "Click the forgot password link on the login page and follow the instructions."
        }
      }.to change(Question, :count).by(1)
        .and change(Answer, :count).by(1)
    end

    it "redirects to the new question" do
      post submit_space_qa_wizard_path(space), params: {
        question_title: "How do I reset my password?",
        question_body: "I've forgotten my password and need to regain access.",
        answer: "Click the forgot password link on the login page."
      }

      expect(response).to redirect_to(question_path(Question.last))
      expect(flash[:notice]).to include("created successfully")
    end

    it "marks the answer as correct" do
      post submit_space_qa_wizard_path(space), params: {
        question_title: "How do I reset my password?",
        question_body: "I've forgotten my password and need to regain access.",
        answer: "Click the forgot password link on the login page."
      }

      expect(Answer.last.is_correct?).to be true
    end

    it "sets robot as author and moderator as sponsor" do
      post submit_space_qa_wizard_path(space), params: {
        question_title: "How do I reset my password?",
        question_body: "I've forgotten my password and need to regain access.",
        answer: "Click the forgot password link on the login page."
      }

      question = Question.last
      expect(question.user).to eq(robot)
      expect(question.sponsored_by).to eq(moderator)
    end

    it "requires all fields" do
      post submit_space_qa_wizard_path(space), params: {
        question_title: "How do I reset my password?",
        question_body: "",
        answer: ""
      }

      expect(response).to have_http_status(:success)
      expect(response.body).to include("required")
    end

    context "when robot user missing" do
      before { robot.destroy }

      it "redirects with error" do
        post submit_space_qa_wizard_path(space), params: {
          question_title: "How do I reset my password?",
          question_body: "Test body content here.",
          answer: "Test answer content here."
        }

        expect(response).to redirect_to(space_qa_wizard_path(space))
        expect(flash[:alert]).to include("robot")
      end
    end
  end

  describe "GET /spaces/:space_id/qa_wizard/articles" do
    let!(:article) { create(:article, spaces: [ space ], title: "Test Article") }

    before { sign_in moderator }

    it "returns articles as JSON" do
      get articles_space_qa_wizard_path(space)

      expect(response).to have_http_status(:success)
      expect(response.content_type).to include("application/json")

      json = JSON.parse(response.body)
      expect(json.length).to eq(1)
      expect(json.first["title"]).to eq("Test Article")
    end
  end

  describe "ensure_llm_available before_action" do
    before { sign_in moderator }

    context "when LLM not available for generate_titles" do
      before { LlmProvider.delete_all }

      it "redirects with error" do
        post generate_titles_space_qa_wizard_path(space), params: {
          source_type: "topic",
          topic_description: "Test",
          count: 2
        }

        expect(response).to redirect_to(space_qa_wizard_path(space))
        expect(flash[:alert]).to include("LLM provider")
      end
    end

    context "when LLM not available for edit" do
      before { LlmProvider.delete_all }

      it "redirects with error" do
        get edit_space_qa_wizard_path(space), params: {
          title: "Test question?",
          source_type: "topic",
          source_data: "test"
        }

        expect(response).to redirect_to(space_qa_wizard_path(space))
        expect(flash[:alert]).to include("LLM provider")
      end
    end

    context "when LLM not available for submit" do
      before { LlmProvider.delete_all }

      it "redirects with error" do
        post submit_space_qa_wizard_path(space), params: {
          question_title: "Test question?",
          question_body: "Test body",
          answer: "Test answer"
        }

        expect(response).to redirect_to(space_qa_wizard_path(space))
        expect(flash[:alert]).to include("LLM provider")
      end
    end
  end

  describe "generate_titles with existing questions" do
    let(:mock_titles) { [ "How do I reset my password?" ] }
    let(:mock_context) { instance_double("RubyLLM::Context") }
    let(:mock_chat) { instance_double(RubyLLM::Chat) }
    # KB content required for topic source
    let!(:article) { create(:article, spaces: [ space ]) }
    let!(:chunk) { create(:chunk, chunkable: article, content: "test topic content") }

    before do
      sign_in moderator
      # Create an existing question to trigger the existing questions branch
      create(:question, space: space, title: "Existing question")
      allow(RubyLLM).to receive(:context).and_return(mock_context)
      allow(mock_context).to receive(:chat).and_return(mock_chat)
      allow(mock_chat).to receive(:ask).and_return(double(content: mock_titles.to_json))
    end

    it "includes existing questions in prompt" do
      post generate_titles_space_qa_wizard_path(space), params: {
        source_type: "topic",
        topic_description: "test topic",
        count: 1
      }

      expect(response).to redirect_to(select_title_space_qa_wizard_path(space))
    end
  end

  describe "generate_titles without existing questions" do
    let(:mock_titles) { [ "How do I reset my password?" ] }
    let(:mock_context) { instance_double("RubyLLM::Context") }
    let(:mock_chat) { instance_double(RubyLLM::Chat) }
    # KB content required for topic source
    let!(:article) { create(:article, spaces: [ space ]) }
    let!(:chunk) { create(:chunk, chunkable: article, content: "test topic content") }

    before do
      sign_in moderator
      # Ensure no existing questions in the space
      space.questions.destroy_all
      allow(RubyLLM).to receive(:context).and_return(mock_context)
      allow(mock_context).to receive(:chat).and_return(mock_chat)
      allow(mock_chat).to receive(:ask).and_return(double(content: mock_titles.to_json))
    end

    it "generates titles without existing questions context" do
      post generate_titles_space_qa_wizard_path(space), params: {
        source_type: "topic",
        topic_description: "test topic",
        count: 1
      }

      expect(response).to redirect_to(select_title_space_qa_wizard_path(space))
    end
  end

  describe "generate_titles RAG with empty chunks" do
    before do
      sign_in moderator
      # No chunks exist, so RAG search should return empty
    end

    it "redirects when no relevant content found" do
      post generate_titles_space_qa_wizard_path(space), params: {
        source_type: "rag",
        query: "nonexistent topic",
        count: 2
      }

      expect(response).to redirect_to(space_qa_wizard_path(space))
      expect(flash[:alert]).to include("No relevant content")
    end
  end

  describe "generate_titles RAG with blank query" do
    let!(:article) { create(:article, spaces: [ space ]) }
    let!(:chunk) { create(:chunk, chunkable: article, content: "Some content") }
    let(:mock_titles) { [ "Generated question?" ] }
    let(:mock_context) { instance_double("RubyLLM::Context") }
    let(:mock_chat) { instance_double(RubyLLM::Chat) }

    before do
      sign_in moderator
      allow(RubyLLM).to receive(:context).and_return(mock_context)
      allow(mock_context).to receive(:chat).and_return(mock_chat)
      allow(mock_chat).to receive(:ask).and_return(double(content: mock_titles.to_json))
    end

    it "uses recent content when query is blank" do
      post generate_titles_space_qa_wizard_path(space), params: {
        source_type: "rag",
        query: "",
        count: 1
      }

      expect(response).to redirect_to(select_title_space_qa_wizard_path(space))
    end
  end

  describe "LLM error handling" do
    let(:mock_client) { instance_double(LlmService::Client) }

    before do
      sign_in moderator
      allow(LlmService::Client).to receive(:new).and_return(mock_client)
    end

    context "when LLM fails during title generation" do
      let!(:article) { create(:article, spaces: [ space ]) }
      let!(:chunk) { create(:chunk, chunkable: article, content: "Test content for searching") }

      before do
        allow(mock_client).to receive(:generate_json).and_raise(StandardError.new("LLM error"))
      end

      it "returns empty titles gracefully" do
        post generate_titles_space_qa_wizard_path(space), params: {
          source_type: "rag",
          query: "test",
          count: 1
        }

        # Should still redirect but with empty titles in session
        expect(response).to redirect_to(select_title_space_qa_wizard_path(space))
      end
    end

    context "when LLM fails during content generation" do
      before do
        allow(mock_client).to receive(:generate_json).and_raise(StandardError.new("LLM error"))
      end

      it "returns empty content gracefully" do
        get edit_space_qa_wizard_path(space), params: {
          title: "Test question?",
          source_type: "topic",
          source_data: "test",
          generate_content: "true"
        }

        expect(response).to have_http_status(:success)
        # Content should be empty due to error
        expect(response.body).to include("Edit FAQ Entry")
      end
    end
  end

  describe "answer generation KB search" do
    # Answer generation now always searches KB using the question title
    let(:mock_content) { { "question_body" => "Body", "answer" => "Answer" } }
    let(:mock_context) { instance_double("RubyLLM::Context") }
    let(:mock_chat) { instance_double(RubyLLM::Chat) }

    before do
      sign_in moderator
      allow(RubyLLM).to receive(:context).and_return(mock_context)
      allow(mock_context).to receive(:chat).and_return(mock_chat)
      allow(mock_chat).to receive(:ask).and_return(double(content: mock_content.to_json))
    end

    context "when KB has relevant content" do
      let!(:article) { create(:article, spaces: [ space ]) }
      # ILIKE searches for exact substring match, so chunk content must contain the query
      # We'll use a simple question that appears as a substring in the content
      let!(:chunk) { create(:chunk, chunkable: article, content: "This article covers password reset procedures and account security.") }

      it "searches KB using question title and finds matching chunks" do
        # "password" is a substring of the chunk content
        get edit_space_qa_wizard_path(space), params: {
          title: "password",
          source_type: "article",
          source_data: "ignored",
          generate_content: "true"
        }

        expect(response).to have_http_status(:success)
      end

      it "works for topic source type" do
        get edit_space_qa_wizard_path(space), params: {
          title: "security",
          source_type: "topic",
          source_data: "ignored",
          generate_content: "true"
        }

        expect(response).to have_http_status(:success)
      end

      it "works for rag source type" do
        get edit_space_qa_wizard_path(space), params: {
          title: "reset",
          source_type: "rag",
          source_data: "ignored",
          generate_content: "true"
        }

        expect(response).to have_http_status(:success)
      end
    end

    context "when KB has no relevant content" do
      # No chunks in the space
      it "still generates content with warning about missing KB context" do
        get edit_space_qa_wizard_path(space), params: {
          title: "Completely unrelated question?",
          source_type: "topic",
          source_data: "test",
          generate_content: "true"
        }

        expect(response).to have_http_status(:success)
      end
    end

    context "with unknown source type" do
      let!(:article) { create(:article, spaces: [ space ]) }
      let!(:chunk) { create(:chunk, chunkable: article, content: "Test content") }

      it "still searches KB using question title" do
        get edit_space_qa_wizard_path(space), params: {
          title: "Test question?",
          source_type: "unknown",
          source_data: "test",
          generate_content: "true"
        }

        expect(response).to have_http_status(:success)
      end
    end
  end

  describe "submit with validation error" do
    before { sign_in moderator }

    it "renders edit on ActiveRecord error" do
      # Create a question that will cause a uniqueness violation or similar
      allow_any_instance_of(Question).to receive(:save!).and_raise(
        ActiveRecord::RecordInvalid.new(Question.new)
      )

      post submit_space_qa_wizard_path(space), params: {
        question_title: "Test question?",
        question_body: "Test body",
        answer: "Test answer"
      }

      expect(response).to have_http_status(:success)
      expect(response.body).to include("Failed to create question")
    end
  end

  describe "GET /spaces/:space_id/qa_wizard/select_title" do
    before { sign_in moderator }

    context "when accessed directly without session data" do
      it "redirects with alert" do
        get select_title_space_qa_wizard_path(space)

        expect(response).to redirect_to(space_qa_wizard_path(space))
        expect(flash[:alert]).to include("No titles available")
      end
    end
  end

  describe "RAG with EmbeddingService available" do
    let!(:embedding_provider) { create(:embedding_provider, :openai, :enabled) }
    let!(:article) { create(:article, spaces: [ space ]) }
    let!(:chunk) { create(:chunk, chunkable: article, content: "Content about features") }
    let(:mock_titles) { [ "Generated question?" ] }
    let(:mock_context) { instance_double("RubyLLM::Context") }
    let(:mock_chat) { instance_double(RubyLLM::Chat) }
    let(:mock_result) do
      Search::ChunkVectorQueryService::Result.new(
        hits: [
          Search::ChunkVectorQueryService::Hit.new(
            id: article.id,
            score: 0.9,
            type: "Article",
            chunkable: article,
            best_chunk: chunk
          )
        ],
        total: 1,
        similarity_threshold: 0.3
      )
    end
    let(:mock_service) { instance_double(Search::ChunkVectorQueryService, call: mock_result) }

    before do
      sign_in moderator
      allow(RubyLLM).to receive(:context).and_return(mock_context)
      allow(mock_context).to receive(:chat).and_return(mock_chat)
      allow(mock_chat).to receive(:ask).and_return(double(content: mock_titles.to_json))
      allow(EmbeddingService).to receive(:available?).and_return(true)
      allow(Search::ChunkVectorQueryService).to receive(:new).and_return(mock_service)
    end

    it "uses vector search when embedding service is available" do
      post generate_titles_space_qa_wizard_path(space), params: {
        source_type: "rag",
        query: "features",
        count: 1
      }

      expect(response).to redirect_to(select_title_space_qa_wizard_path(space))
      expect(Search::ChunkVectorQueryService).to have_received(:new).with(
        q: "features",
        space_id: space.id,
        limit: 10,
        types: %w[Article]
      )
    end
  end
end
