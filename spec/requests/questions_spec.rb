# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Questions" do
  describe "GET /questions" do
    it "returns http success" do
      get questions_path
      expect(response).to have_http_status(:success)
    end

    it "displays questions" do
      question = create(:question)

      get questions_path

      expect(response.body).to include(question.title)
      expect(response.body).to include(question.category.name)
      expect(response.body).to include(question.author.display_name)
    end

    it "shows message when no questions exist" do
      get questions_path

      expect(response.body).to include("No questions yet.")
    end

    context "with category filter" do
      it "filters questions by category" do
        category1 = create(:category, name: "Ruby")
        category2 = create(:category, name: "Python")
        ruby_question = create(:question, category: category1)
        python_question = create(:question, category: category2)

        get questions_path(category: category1.slug)

        expect(response.body).to include(ruby_question.title)
        expect(response.body).not_to include(python_question.title)
      end
    end

    it "shows solved status for questions with correct answers" do
      question = create(:question)
      create(:answer, question: question, is_correct: true)

      get questions_path

      expect(response.body).to include("badge-success")
      expect(response.body).to include("Solved")
    end
  end

  describe "GET /questions/:id" do
    it "returns http success" do
      question = create(:question)

      get question_path(question)

      expect(response).to have_http_status(:success)
    end

    it "displays the question" do
      question = create(:question)

      get question_path(question)

      expect(response.body).to include(question.title)
      expect(response.body).to include(question.body)
      expect(response.body).to include(question.author.display_name)
      expect(response.body).to include(question.category.name)
    end

    it "displays answers ordered by votes" do
      question = create(:question)
      low_vote_answer = create(:answer, question: question, body: "Low vote answer body here", vote_score: 1)
      high_vote_answer = create(:answer, question: question, body: "High vote answer body here", vote_score: 10)

      get question_path(question)

      expect(response.body).to include("Low vote answer body here")
      expect(response.body).to include("High vote answer body here")
      # High vote answer should appear first
      expect(response.body.index("High vote answer")).to be < response.body.index("Low vote answer")
    end

    it "highlights the correct answer" do
      question = create(:question)
      create(:answer, question: question, is_correct: true, body: "This is the correct answer")

      get question_path(question)

      expect(response.body).to include("Solved")
    end

    it "shows message when no answers exist" do
      question = create(:question)

      get question_path(question)

      expect(response.body).to include("No answers yet")
    end

    it "displays comments on the question" do
      question = create(:question)
      comment = create(:comment, commentable: question, body: "This is a question comment")

      get question_path(question)

      expect(response.body).to include("This is a question comment")
      expect(response.body).to include(comment.author.display_name)
    end

    it "displays nested comment replies" do
      question = create(:question)
      parent_comment = create(:comment, commentable: question, body: "Parent comment text")
      reply = create(:comment, commentable: question, parent_comment: parent_comment, body: "Reply comment text")

      get question_path(question)

      expect(response.body).to include("Parent comment text")
      expect(response.body).to include("Reply comment text")
      expect(response.body).to include(reply.author.display_name)
    end

    it "displays comments on answers" do
      question = create(:question)
      answer = create(:answer, question: question)
      comment = create(:comment, commentable: answer, body: "This is an answer comment")

      get question_path(question)

      expect(response.body).to include("This is an answer comment")
      expect(response.body).to include(comment.author.display_name)
    end

    it "shows comment count" do
      question = create(:question)
      create(:comment, commentable: question)
      create(:comment, commentable: question)

      get question_path(question)

      expect(response.body).to include("2 comments")
    end
  end

  describe "POST /questions/:id/upvote" do
    let(:user) { create(:user) }
    let(:question) { create(:question, vote_score: 0) }

    context "when signed in" do
      before { sign_in user }

      it "upvotes the question" do
        post upvote_question_path(question)

        expect(question.reload.vote_score).to eq(1)
      end

      it "redirects to the question" do
        post upvote_question_path(question)

        expect(response).to redirect_to(question_path(question))
      end

      it "responds with turbo_stream when requested" do
        post upvote_question_path(question), headers: { "Accept" => "text/vnd.turbo-stream.html" }

        expect(response.media_type).to eq("text/vnd.turbo-stream.html")
        expect(response.body).to include("turbo-stream")
      end
    end
  end

  describe "POST /questions/:id/downvote" do
    let(:user) { create(:user) }
    let(:question) { create(:question, vote_score: 0) }

    context "when signed in" do
      before { sign_in user }

      it "downvotes the question" do
        post downvote_question_path(question)

        expect(question.reload.vote_score).to eq(-1)
      end

      it "redirects to the question" do
        post downvote_question_path(question)

        expect(response).to redirect_to(question_path(question))
      end
    end
  end

  describe "DELETE /questions/:id/remove_vote" do
    let(:user) { create(:user) }
    let(:question_author) { create(:user) }
    let(:question) { create(:question, user: question_author, vote_score: 1) }

    before do
      sign_in user
      create(:question_vote, question: question, user: user, value: 1)
    end

    it "removes the vote" do
      delete remove_vote_question_path(question)

      expect(question.reload.vote_score).to eq(0)
    end

    it "redirects to the question" do
      delete remove_vote_question_path(question)

      expect(response).to redirect_to(question_path(question))
    end
  end
end
