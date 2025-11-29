# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Comments" do
  let(:user) { create(:user) }

  describe "POST /questions/:question_id/comments" do
    let(:question) { create(:question) }

    context "when signed in" do
      before { sign_in user }

      it "creates a new comment on a question" do
        expect {
          post question_comments_path(question), params: { comment: { body: "Great question!" } }
        }.to change(Comment, :count).by(1)
      end

      it "redirects to the question with anchor" do
        post question_comments_path(question), params: { comment: { body: "Great question!" } }
        expect(response).to redirect_to(question_path(question, anchor: "comment-#{Comment.last.id}"))
      end

      it "sets the current user as author" do
        post question_comments_path(question), params: { comment: { body: "Great question!" } }
        expect(Comment.last.user).to eq(user)
      end

      it "does not create a comment with blank body" do
        expect {
          post question_comments_path(question), params: { comment: { body: "" } }
        }.not_to change(Comment, :count)
      end
    end

    context "when not signed in" do
      it "redirects to sign in" do
        post question_comments_path(question), params: { comment: { body: "Great question!" } }
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe "POST /answers/:answer_id/comments" do
    let(:answer) { create(:answer) }

    context "when signed in" do
      before { sign_in user }

      it "creates a new comment on an answer" do
        expect {
          post answer_comments_path(answer), params: { comment: { body: "Great answer!" } }
        }.to change(Comment, :count).by(1)
      end

      it "redirects to the question with anchor" do
        post answer_comments_path(answer), params: { comment: { body: "Great answer!" } }
        expect(response).to redirect_to(question_path(answer.question, anchor: "comment-#{Comment.last.id}"))
      end
    end
  end

  describe "POST /comments/:id/comments (replies)" do
    let(:question) { create(:question) }
    let(:parent_comment) { create(:comment, commentable: question) }

    context "when signed in" do
      before { sign_in user }

      it "creates a reply to a comment" do
        parent_comment # Force creation before the expect block
        expect {
          post comment_replies_path(parent_comment), params: { comment: { body: "Great point!" } }
        }.to change(Comment, :count).by(1)
      end

      it "sets the parent comment" do
        post comment_replies_path(parent_comment), params: { comment: { body: "Great point!" } }
        expect(Comment.last.parent_comment).to eq(parent_comment)
      end
    end
  end

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
