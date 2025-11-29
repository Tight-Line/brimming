# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Comments" do
  let(:user) { create(:user) }

  describe "POST /comments/:id/upvote" do
    let(:question) { create(:question) }
    let(:comment) { create(:comment, commentable: question, vote_score: 0) }

    context "when signed in" do
      before { sign_in user }

      it "upvotes the comment" do
        post upvote_comment_path(comment)

        expect(comment.reload.vote_score).to eq(1)
      end

      it "redirects back" do
        post upvote_comment_path(comment)

        expect(response).to redirect_to(root_path)
      end

      it "responds with turbo_stream when requested" do
        post upvote_comment_path(comment), headers: { "Accept" => "text/vnd.turbo-stream.html" }

        expect(response.media_type).to eq("text/vnd.turbo-stream.html")
        expect(response.body).to include("turbo-stream")
      end
    end
  end

  describe "DELETE /comments/:id/remove_vote" do
    let(:comment_author) { create(:user) }
    let(:question) { create(:question) }
    let(:comment) { create(:comment, commentable: question, user: comment_author, vote_score: 1) }

    before do
      sign_in user
      create(:comment_vote, comment: comment, user: user)
    end

    it "removes the vote" do
      delete remove_vote_comment_path(comment)

      expect(comment.reload.vote_score).to eq(0)
    end

    it "redirects back" do
      delete remove_vote_comment_path(comment)

      expect(response).to redirect_to(root_path)
    end
  end
end
