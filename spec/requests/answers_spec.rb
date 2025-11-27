# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Answers" do
  describe "POST /answers/:id/upvote" do
    let(:answer) { create(:answer, vote_score: 0) }

    context "when signed in" do
      before { create(:user) } # Creates user for current_user stub

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
      before { create(:user) }

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
    let!(:voter) { create(:user) } # Created first so it's User.first (current_user)
    let(:answer_author) { create(:user) }
    let(:answer) { create(:answer, user: answer_author, vote_score: 1) }

    before do
      create(:vote, answer: answer, user: voter, value: 1)
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
