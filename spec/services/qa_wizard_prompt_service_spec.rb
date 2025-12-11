# frozen_string_literal: true

require "rails_helper"

RSpec.describe QaWizardPromptService do
  let(:space) { create(:space, name: "Test Space", description: "A test space for Q&A") }
  let(:service) { described_class.new(space) }

  describe "#effective_persona" do
    context "when space has no custom prompt" do
      it "returns the default persona from SearchSetting" do
        expect(service.effective_persona).to include("{{SPACE_NAME}}")
        expect(service.effective_persona).to include("{{SPACE_DESCRIPTION}}")
      end
    end

    context "when space has a custom prompt" do
      before { space.update!(qa_wizard_prompt: "Custom persona for {{SPACE_NAME}}") }

      it "returns the custom persona" do
        expect(service.effective_persona).to eq("Custom persona for {{SPACE_NAME}}")
      end
    end
  end

  describe "#custom_prompt?" do
    context "when space has no custom prompt" do
      it "returns false" do
        expect(service.custom_prompt?).to be false
      end
    end

    context "when space has a custom prompt" do
      before { space.update!(qa_wizard_prompt: "Custom prompt") }

      it "returns true" do
        expect(service.custom_prompt?).to be true
      end
    end
  end

  describe "#build_content_prompt" do
    let(:article) { create(:article, title: "Test Article", user: create(:user, username: "author1")) }
    let(:chunks) do
      [
        create(:chunk, chunkable: article, content: "This is chunk 1 content")
      ]
    end

    it "interpolates SPACE_NAME" do
      prompt = service.build_content_prompt(title: "How do I test?", chunks: [])
      expect(prompt).to include("Test Space")
    end

    it "interpolates SPACE_DESCRIPTION" do
      prompt = service.build_content_prompt(title: "How do I test?", chunks: [])
      expect(prompt).to include("A test space for Q&A")
    end

    context "when space has no description" do
      let(:space) { create(:space, name: "Empty Space", description: nil) }

      it "handles blank description gracefully" do
        prompt = service.build_content_prompt(title: "How do I test?", chunks: [])
        expect(prompt).to include("Empty Space")
        expect(prompt).not_to include("Space Description:")
      end
    end

    it "includes the question title" do
      prompt = service.build_content_prompt(title: "How do I test?", chunks: [])
      expect(prompt).to include("QUESTION TITLE: How do I test?")
    end

    context "with chunks" do
      it "includes chunk content in RAG_CONTEXT" do
        prompt = service.build_content_prompt(title: "How do I test?", chunks: chunks)
        expect(prompt).to include("This is chunk 1 content")
      end

      it "includes source metadata" do
        prompt = service.build_content_prompt(title: "How do I test?", chunks: chunks)
        expect(prompt).to include("Type: Article")
        expect(prompt).to include("Title: Test Article")
        expect(prompt).to include("Author: author1")
      end
    end

    context "without chunks" do
      it "includes empty context message" do
        prompt = service.build_content_prompt(title: "How do I test?", chunks: [])
        expect(prompt).to include("No relevant content found")
      end
    end

    context "with custom persona" do
      before do
        space.update!(qa_wizard_prompt: "You are an expert FAQ writer for {{SPACE_NAME}}.")
      end

      it "uses the custom persona and appends fixed instructions" do
        prompt = service.build_content_prompt(title: "How do I test?", chunks: chunks)
        # Custom persona is used
        expect(prompt).to include("You are an expert FAQ writer for Test Space.")
        # Fixed instructions are always appended
        expect(prompt).to include("Context from Knowledge Base")
        expect(prompt).to include("This is chunk 1 content")
        expect(prompt).to include("Response Format")
        expect(prompt).to include("JSON only")
      end
    end
  end

  describe "source metadata extraction" do
    let(:user) { create(:user, username: "testuser") }

    context "for Article sources" do
      let(:article) { create(:article, title: "My Article", user: user) }
      let(:chunk) { create(:chunk, chunkable: article, content: "Article content") }

      it "extracts article metadata" do
        prompt = service.build_content_prompt(title: "Test", chunks: [ chunk ])
        expect(prompt).to include("Type: Article")
        expect(prompt).to include("Title: My Article")
        expect(prompt).to include("Author: testuser")
      end
    end

    context "for Question sources" do
      let(:question) { create(:question, title: "My Question", user: user, space: space) }
      let(:chunk) { create(:chunk, chunkable: question, content: "Question content") }

      it "extracts question metadata" do
        prompt = service.build_content_prompt(title: "Test", chunks: [ chunk ])
        expect(prompt).to include("Type: Question")
        expect(prompt).to include("Title: My Question")
        expect(prompt).to include("Author: testuser")
      end
    end

    context "for Answer sources" do
      let(:question) { create(:question, title: "Parent Question", user: user, space: space) }
      let(:answer) { create(:answer, question: question, user: user) }
      let(:chunk) { create(:chunk, chunkable: answer, content: "Answer content") }

      it "extracts answer metadata" do
        prompt = service.build_content_prompt(title: "Test", chunks: [ chunk ])
        expect(prompt).to include("Type: Answer")
        expect(prompt).to include("Title: Answer to: Parent Question")
        expect(prompt).to include("Author: testuser")
      end
    end

    context "for unknown source types" do
      let(:comment) { create(:comment, user: user) }
      let(:chunk) { create(:chunk, chunkable: comment, content: "Comment content") }

      it "extracts generic metadata" do
        prompt = service.build_content_prompt(title: "Test", chunks: [ chunk ])
        expect(prompt).to include("Type: Comment")
        expect(prompt).to include("Author: Unknown")
      end
    end
  end
end
