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
      expect(response.body).to include(question.space.name)
      expect(response.body).to include(question.author.display_name)
    end

    it "shows message when no questions exist" do
      get questions_path

      expect(response.body).to include("No questions yet.")
    end

    context "with space filter" do
      it "filters questions by space" do
        space1 = create(:space, name: "Ruby")
        space2 = create(:space, name: "Python")
        ruby_question = create(:question, space: space1)
        python_question = create(:question, space: space2)

        get questions_path(space: space1.slug)

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
      expect(response.body).to include(question.space.name)
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

  describe "GET /questions/new" do
    context "when signed in" do
      let(:user) { create(:user) }

      before { sign_in user }

      it "returns http success" do
        create(:space) # need at least one space
        get new_question_path
        expect(response).to have_http_status(:success)
      end

      it "displays the question form" do
        space = create(:space, name: "Ruby")
        get new_question_path
        expect(response.body).to include("Ask a Question")
        expect(response.body).to include("Ruby")
      end
    end

    context "when not signed in" do
      it "redirects to sign in" do
        get new_question_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe "POST /questions" do
    let(:user) { create(:user) }
    let(:space) { create(:space) }

    context "when signed in" do
      before { sign_in user }

      context "with valid parameters" do
        let(:valid_params) do
          {
            question: {
              title: "How do I use Ruby blocks?",
              body: "I am trying to understand how blocks work in Ruby. Can someone explain with examples?",
              space_id: space.id
            }
          }
        end

        it "creates a new question" do
          expect {
            post questions_path, params: valid_params
          }.to change(Question, :count).by(1)
        end

        it "redirects to the question" do
          post questions_path, params: valid_params
          expect(response).to redirect_to(question_path(Question.last))
        end

        it "sets the current user as author" do
          post questions_path, params: valid_params
          expect(Question.last.user).to eq(user)
        end
      end

      context "with invalid parameters" do
        it "does not create a question with blank title" do
          expect {
            post questions_path, params: { question: { title: "", body: "A" * 20, space_id: space.id } }
          }.not_to change(Question, :count)
        end

        it "re-renders the form" do
          post questions_path, params: { question: { title: "", body: "A" * 20, space_id: space.id } }
          expect(response).to have_http_status(:unprocessable_entity)
        end
      end
    end

    context "when not signed in" do
      it "redirects to sign in" do
        post questions_path, params: { question: { title: "Test", body: "A" * 20, space_id: space.id } }
        expect(response).to redirect_to(new_user_session_path)
      end
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
