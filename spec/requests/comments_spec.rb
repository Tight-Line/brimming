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

  describe "GET /comments/:id/edit" do
    let(:question) { create(:question) }
    let(:comment) { create(:comment, commentable: question, user: user) }

    context "when signed in as owner" do
      before { sign_in user }

      it "returns http success" do
        get edit_comment_path(comment)
        expect(response).to have_http_status(:success)
      end

      it "displays the edit form" do
        get edit_comment_path(comment)
        expect(response.body).to include("Edit Comment")
        expect(response.body).to include(comment.body)
      end
    end

    context "when signed in as different user" do
      let(:other_user) { create(:user) }

      before { sign_in other_user }

      it "redirects with alert" do
        get edit_comment_path(comment)
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to be_present
      end
    end

    context "when not signed in" do
      it "redirects to sign in" do
        get edit_comment_path(comment)
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe "PATCH /comments/:id" do
    let(:question) { create(:question) }
    let(:comment) { create(:comment, commentable: question, user: user) }

    context "when signed in as owner" do
      before { sign_in user }

      context "with valid parameters" do
        it "updates the comment" do
          patch comment_path(comment), params: { comment: { body: "Updated comment body" } }
          expect(comment.reload.body).to eq("Updated comment body")
        end

        it "records the edit" do
          patch comment_path(comment), params: { comment: { body: "Updated comment body" } }
          expect(comment.reload.edited?).to be true
          expect(comment.last_editor).to eq(user)
        end

        it "redirects to the question with anchor" do
          patch comment_path(comment), params: { comment: { body: "Updated comment body" } }
          expect(response).to redirect_to(question_path(question, anchor: "comment-#{comment.id}"))
        end
      end

      context "with invalid parameters" do
        it "does not update the comment" do
          original_body = comment.body
          patch comment_path(comment), params: { comment: { body: "" } }
          expect(comment.reload.body).to eq(original_body)
        end

        it "re-renders the edit form" do
          patch comment_path(comment), params: { comment: { body: "" } }
          expect(response).to have_http_status(:unprocessable_entity)
        end
      end
    end

    context "when signed in as different user" do
      let(:other_user) { create(:user) }

      before { sign_in other_user }

      it "does not update the comment" do
        original_body = comment.body
        patch comment_path(comment), params: { comment: { body: "Hacked" } }
        expect(comment.reload.body).to eq(original_body)
      end

      it "redirects with alert" do
        patch comment_path(comment), params: { comment: { body: "Hacked" } }
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to be_present
      end
    end

    context "when not signed in" do
      it "redirects to sign in" do
        patch comment_path(comment), params: { comment: { body: "New body" } }
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe "DELETE /comments/:id" do
    let(:question) { create(:question) }
    let!(:comment) { create(:comment, commentable: question, user: user) }

    context "when signed in as owner" do
      before { sign_in user }

      it "soft deletes the comment" do
        expect {
          delete comment_path(comment)
        }.not_to change(Comment, :count)

        expect(comment.reload.deleted?).to be true
      end

      it "redirects to the comment" do
        delete comment_path(comment)
        expect(response).to redirect_to(question_path(question, anchor: "comment-#{comment.id}"))
      end
    end

    context "when signed in as different user" do
      let(:other_user) { create(:user) }

      before { sign_in other_user }

      it "does not soft delete the comment" do
        delete comment_path(comment)
        expect(comment.reload.deleted?).to be false
      end

      it "redirects with alert" do
        delete comment_path(comment)
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to be_present
      end
    end

    context "when not signed in" do
      it "redirects to sign in" do
        delete comment_path(comment)
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe "comment on answer" do
    let(:answer) { create(:answer) }
    let(:comment) { create(:comment, commentable: answer, user: user) }

    context "when editing" do
      before { sign_in user }

      it "redirects to the question containing the answer" do
        patch comment_path(comment), params: { comment: { body: "Updated comment" } }
        expect(response).to redirect_to(question_path(answer.question, anchor: "comment-#{comment.id}"))
      end
    end

    context "when deleting" do
      before { sign_in user }

      it "redirects to the comment" do
        delete comment_path(comment)
        expect(response).to redirect_to(question_path(answer.question, anchor: "comment-#{comment.id}"))
      end
    end
  end

  describe "reply to comment on question" do
    let(:question) { create(:question) }
    let(:parent_comment) { create(:comment, commentable: question) }
    let(:reply) { create(:comment, commentable: question, parent_comment: parent_comment, user: user) }

    context "when deleting" do
      before { sign_in user }

      it "redirects to the reply (soft deleted)" do
        delete comment_path(reply)
        expect(response).to redirect_to(question_path(question, anchor: "comment-#{reply.id}"))
      end
    end
  end

  describe "reply to comment on answer" do
    let(:answer) { create(:answer) }
    let(:parent_comment) { create(:comment, commentable: answer) }
    let(:reply) { create(:comment, commentable: answer, parent_comment: parent_comment, user: user) }

    context "when deleting" do
      before { sign_in user }

      it "redirects to the reply (soft deleted)" do
        delete comment_path(reply)
        expect(response).to redirect_to(question_path(answer.question, anchor: "comment-#{reply.id}"))
      end
    end
  end

  describe "DELETE /comments/:id/hard_delete" do
    let(:question) { create(:question) }
    let(:space) { question.space }
    let!(:comment) { create(:comment, commentable: question) }

    context "when signed in as admin" do
      let(:admin) { create(:user, role: :admin) }

      before { sign_in admin }

      it "permanently deletes the comment" do
        expect {
          delete hard_delete_comment_path(comment)
        }.to change(Comment, :count).by(-1)
      end

      it "also deletes child replies" do
        reply1 = create(:comment, commentable: question, parent_comment: comment)
        create(:comment, commentable: question, parent_comment: reply1)

        expect {
          delete hard_delete_comment_path(comment)
        }.to change(Comment, :count).by(-3)
      end

      it "redirects to the question" do
        delete hard_delete_comment_path(comment)
        expect(response).to redirect_to(question_path(question))
      end

      context "when comment is a reply" do
        let(:parent) { create(:comment, commentable: question) }
        let!(:reply) { create(:comment, commentable: question, parent_comment: parent) }

        it "redirects to parent comment anchor" do
          delete hard_delete_comment_path(reply)
          expect(response).to redirect_to(question_path(question, anchor: "comment-#{parent.id}"))
        end
      end

      context "when comment is on an answer" do
        let(:answer) { create(:answer, question: question) }
        let!(:answer_comment) { create(:comment, commentable: answer) }

        it "redirects to the answer anchor" do
          delete hard_delete_comment_path(answer_comment)
          expect(response).to redirect_to(question_path(question, anchor: "answer-#{answer.id}"))
        end
      end
    end

    context "when signed in as space moderator" do
      let(:moderator) { create(:user) }

      before do
        create(:space_moderator, space: space, user: moderator)
        sign_in moderator
      end

      it "permanently deletes the comment" do
        expect {
          delete hard_delete_comment_path(comment)
        }.to change(Comment, :count).by(-1)
      end
    end

    context "when signed in as regular user" do
      before { sign_in user }

      it "does not delete the comment" do
        expect {
          delete hard_delete_comment_path(comment)
        }.not_to change(Comment, :count)
      end

      it "redirects with alert" do
        delete hard_delete_comment_path(comment)
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to be_present
      end
    end

    context "when not signed in" do
      it "redirects to sign in" do
        delete hard_delete_comment_path(comment)
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end
end
