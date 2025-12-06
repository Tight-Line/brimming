# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Bookmarks" do
  let(:user) { create(:user) }

  describe "GET /bookmarks" do
    context "when signed in" do
      before { sign_in user }

      it "returns http success" do
        get bookmarks_path
        expect(response).to have_http_status(:success)
      end

      it "displays the user's bookmarks" do
        question = create(:question)
        create(:bookmark, user: user, bookmarkable: question)

        get bookmarks_path
        expect(response.body).to include(question.title)
      end

      it "does not display other users' bookmarks" do
        other_user = create(:user)
        other_question = create(:question, title: "Other User's Bookmarked Question")
        create(:bookmark, user: other_user, bookmarkable: other_question)

        get bookmarks_path
        expect(response.body).not_to include(other_question.title)
      end

      it "filters by type when specified" do
        question = create(:question, title: "Bookmarked Question Title")
        article = create(:article, title: "Bookmarked Article Title")
        create(:bookmark, user: user, bookmarkable: question)
        create(:bookmark, user: user, bookmarkable: article)

        get bookmarks_path(type: "Question")
        expect(response.body).to include("Bookmarked Question Title")
        expect(response.body).not_to include("Bookmarked Article Title")
      end
    end

    context "when not signed in" do
      it "redirects to sign in" do
        get bookmarks_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe "POST /bookmarks" do
    let(:question) { create(:question) }

    context "when signed in" do
      before { sign_in user }

      it "creates a new bookmark" do
        expect {
          post bookmarks_path, params: { bookmark: { bookmarkable_type: "Question", bookmarkable_id: question.id } }
        }.to change(Bookmark, :count).by(1)
      end

      it "redirects back" do
        post bookmarks_path, params: { bookmark: { bookmarkable_type: "Question", bookmarkable_id: question.id } }
        expect(response).to redirect_to(root_path)
      end

      it "responds with turbo_stream when requested" do
        post bookmarks_path,
          params: { bookmark: { bookmarkable_type: "Question", bookmarkable_id: question.id } },
          headers: { "Accept" => "text/vnd.turbo-stream.html" }

        expect(response.media_type).to eq("text/vnd.turbo-stream.html")
        expect(response.body).to include("turbo-stream")
      end

      it "creates bookmark with notes" do
        post bookmarks_path, params: {
          bookmark: { bookmarkable_type: "Question", bookmarkable_id: question.id, notes: "Important question" }
        }
        expect(Bookmark.last.notes).to eq("Important question")
      end

      it "does not create duplicate bookmark" do
        create(:bookmark, user: user, bookmarkable: question)

        expect {
          post bookmarks_path, params: { bookmark: { bookmarkable_type: "Question", bookmarkable_id: question.id } }
        }.not_to change(Bookmark, :count)
      end

      it "does not create bookmark for invalid bookmarkable type" do
        expect {
          post bookmarks_path, params: { bookmark: { bookmarkable_type: "InvalidType", bookmarkable_id: question.id } }
        }.not_to change(Bookmark, :count)
      end
    end

    context "when not signed in" do
      it "redirects to sign in" do
        post bookmarks_path, params: { bookmark: { bookmarkable_type: "Question", bookmarkable_id: question.id } }
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe "PATCH /bookmarks/:id" do
    let(:question) { create(:question) }
    let(:bookmark) { create(:bookmark, user: user, bookmarkable: question) }

    context "when signed in as owner" do
      before { sign_in user }

      it "updates the bookmark notes" do
        patch bookmark_path(bookmark), params: { bookmark: { notes: "Updated notes" } }
        expect(bookmark.reload.notes).to eq("Updated notes")
      end

      it "redirects to bookmarks index" do
        patch bookmark_path(bookmark), params: { bookmark: { notes: "Updated notes" } }
        expect(response).to redirect_to(bookmarks_path)
      end

      it "responds with turbo_stream when requested" do
        patch bookmark_path(bookmark),
          params: { bookmark: { notes: "Updated notes" } },
          headers: { "Accept" => "text/vnd.turbo-stream.html" }

        expect(response.media_type).to eq("text/vnd.turbo-stream.html")
      end
    end

    context "when signed in as different user" do
      let(:other_user) { create(:user) }

      before { sign_in other_user }

      it "redirects with not authorized message" do
        patch bookmark_path(bookmark), params: { bookmark: { notes: "Hacked notes" } }
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to eq("You are not authorized to perform this action.")
      end

      it "does not update the bookmark" do
        patch bookmark_path(bookmark), params: { bookmark: { notes: "Hacked notes" } }
        expect(bookmark.reload.notes).not_to eq("Hacked notes")
      end
    end

    context "when update fails" do
      before { sign_in user }

      it "redirects with error message on HTML format" do
        allow_any_instance_of(Bookmark).to receive(:update).and_return(false)

        patch bookmark_path(bookmark), params: { bookmark: { notes: "Updated notes" } }
        expect(response).to redirect_to(bookmarks_path)
        expect(flash[:alert]).to eq("Could not update bookmark.")
      end

      it "returns unprocessable entity on turbo_stream format" do
        allow_any_instance_of(Bookmark).to receive(:update).and_return(false)

        patch bookmark_path(bookmark),
          params: { bookmark: { notes: "Updated notes" } },
          headers: { "Accept" => "text/vnd.turbo-stream.html" }

        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe "DELETE /bookmarks/:id" do
    let(:question) { create(:question) }
    let!(:bookmark) { create(:bookmark, user: user, bookmarkable: question) }

    context "when signed in as owner" do
      before { sign_in user }

      it "destroys the bookmark" do
        expect {
          delete bookmark_path(bookmark)
        }.to change(Bookmark, :count).by(-1)
      end

      it "redirects back" do
        delete bookmark_path(bookmark)
        expect(response).to redirect_to(bookmarks_path)
      end

      it "responds with turbo_stream when requested (from content page)" do
        delete bookmark_path(bookmark), headers: { "Accept" => "text/vnd.turbo-stream.html" }

        expect(response.media_type).to eq("text/vnd.turbo-stream.html")
        expect(response.body).to include("turbo-stream")
        expect(response.body).to include("bookmark-question-#{question.id}")
      end

      it "responds with turbo_stream remove when from_index param is set" do
        bookmark_id = bookmark.id
        delete bookmark_path(bookmark, from_index: true), headers: { "Accept" => "text/vnd.turbo-stream.html" }

        expect(response.media_type).to eq("text/vnd.turbo-stream.html")
        expect(response.body).to include("turbo-stream")
        expect(response.body).to include("bookmark_#{bookmark_id}")
      end
    end

    context "when signed in as different user" do
      let(:other_user) { create(:user) }

      before { sign_in other_user }

      it "redirects with not authorized message" do
        delete bookmark_path(bookmark)
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to eq("You are not authorized to perform this action.")
      end

      it "does not destroy the bookmark" do
        expect {
          delete bookmark_path(bookmark)
        }.not_to change(Bookmark, :count)
      end
    end

    context "when not signed in" do
      it "redirects to sign in" do
        delete bookmark_path(bookmark)
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe "bookmarking different content types" do
    before { sign_in user }

    it "bookmarks an answer" do
      answer = create(:answer)
      expect {
        post bookmarks_path, params: { bookmark: { bookmarkable_type: "Answer", bookmarkable_id: answer.id } }
      }.to change(Bookmark, :count).by(1)
      expect(Bookmark.last.bookmarkable).to eq(answer)
    end

    it "bookmarks a comment" do
      comment = create(:comment)
      expect {
        post bookmarks_path, params: { bookmark: { bookmarkable_type: "Comment", bookmarkable_id: comment.id } }
      }.to change(Bookmark, :count).by(1)
      expect(Bookmark.last.bookmarkable).to eq(comment)
    end

    it "bookmarks an article" do
      article = create(:article)
      expect {
        post bookmarks_path, params: { bookmark: { bookmarkable_type: "Article", bookmarkable_id: article.id } }
      }.to change(Bookmark, :count).by(1)
      expect(Bookmark.last.bookmarkable).to eq(article)
    end
  end
end
