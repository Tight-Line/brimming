# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Answers" do
  let(:user) { create(:user) }

  describe "POST /questions/:question_id/answers" do
    let(:question) { create(:question) }

    context "when signed in" do
      before { sign_in user }

      context "with valid parameters" do
        let(:valid_params) do
          { answer: { body: "This is a detailed answer that explains the solution to your problem." } }
        end

        it "creates a new answer" do
          expect {
            post question_answers_path(question), params: valid_params
          }.to change(Answer, :count).by(1)
        end

        it "redirects to the question with anchor" do
          post question_answers_path(question), params: valid_params
          expect(response).to redirect_to(question_path(question, anchor: "answer-#{Answer.last.id}"))
        end

        it "sets the current user as author" do
          post question_answers_path(question), params: valid_params
          expect(Answer.last.user).to eq(user)
        end

        it "associates the answer with the question" do
          post question_answers_path(question), params: valid_params
          expect(Answer.last.question).to eq(question)
        end
      end

      context "with invalid parameters" do
        it "does not create an answer with body too short" do
          expect {
            post question_answers_path(question), params: { answer: { body: "short" } }
          }.not_to change(Answer, :count)
        end

        it "re-renders the question page" do
          post question_answers_path(question), params: { answer: { body: "short" } }
          expect(response).to have_http_status(:unprocessable_entity)
        end
      end
    end

    context "when not signed in" do
      it "redirects to sign in" do
        post question_answers_path(question), params: { answer: { body: "A" * 20 } }
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe "POST /answers/:id/upvote" do
    let(:answer) { create(:answer, vote_score: 0) }

    context "when signed in" do
      before { sign_in user }

      it "upvotes the answer" do
        post upvote_answer_path(answer)

        expect(answer.reload.vote_score).to eq(1)
      end

      it "redirects to the question" do
        post upvote_answer_path(answer)

        expect(response).to redirect_to(question_path(answer.question))
      end

      it "responds with turbo_stream when requested" do
        post upvote_answer_path(answer), headers: { "Accept" => "text/vnd.turbo-stream.html" }

        expect(response.media_type).to eq("text/vnd.turbo-stream.html")
        expect(response.body).to include("turbo-stream")
      end
    end
  end

  describe "POST /answers/:id/downvote" do
    let(:answer) { create(:answer, vote_score: 0) }

    context "when signed in" do
      before { sign_in user }

      it "downvotes the answer" do
        post downvote_answer_path(answer)

        expect(answer.reload.vote_score).to eq(-1)
      end

      it "redirects to the question" do
        post downvote_answer_path(answer)

        expect(response).to redirect_to(question_path(answer.question))
      end
    end
  end

  describe "DELETE /answers/:id/remove_vote" do
    let(:answer_author) { create(:user) }
    let(:answer) { create(:answer, user: answer_author, vote_score: 1) }

    before do
      sign_in user
      create(:vote, answer: answer, user: user, value: 1)
    end

    it "removes the vote" do
      delete remove_vote_answer_path(answer)

      expect(answer.reload.vote_score).to eq(0)
    end

    it "redirects to the question" do
      delete remove_vote_answer_path(answer)

      expect(response).to redirect_to(question_path(answer.question))
    end
  end
end
