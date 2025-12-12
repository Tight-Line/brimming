# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Articles" do
  describe "GET /articles" do
    it "returns http success" do
      get articles_path
      expect(response).to have_http_status(:success)
    end

    it "displays articles" do
      article = create(:article)

      get articles_path

      expect(response.body).to include(article.title)
      expect(response.body).to include(article.user.display_name)
    end

    it "shows message when no articles exist" do
      get articles_path

      expect(response.body).to include("No articles yet.")
    end

    it "shows orphaned badge for articles without spaces" do
      create(:article)

      get articles_path

      expect(response.body).to include("Orphaned")
    end

    it "shows space names for articles with spaces" do
      space = create(:space, name: "Ruby")
      article = create(:article)
      create(:article_space, article: article, space: space)

      get articles_path

      expect(response.body).to include("Ruby")
    end

    context "with space filter" do
      it "filters articles by space" do
        space1 = create(:space, name: "Ruby")
        space2 = create(:space, name: "Python")
        ruby_article = create(:article, title: "Ruby Article Title")
        python_article = create(:article, title: "Python Article Title")
        create(:article_space, article: ruby_article, space: space1)
        create(:article_space, article: python_article, space: space2)

        get articles_path(space: space1.slug)

        expect(response.body).to include("Ruby Article Title")
        expect(response.body).not_to include("Python Article Title")
      end
    end
  end

  describe "GET /articles/:id" do
    it "returns http success" do
      article = create(:article)

      get article_path(article)

      expect(response).to have_http_status(:success)
    end

    it "uses slug in URL" do
      article = create(:article, title: "My Great Article")

      expect(article_path(article)).to eq("/articles/#{article.slug}")
      get article_path(article)

      expect(response).to have_http_status(:success)
    end

    it "displays the article" do
      article = create(:article, body: "Article body content here")

      get article_path(article)

      expect(response.body).to include(article.title)
      expect(response.body).to include("Article body content here")
      expect(response.body).to include(article.user.display_name)
    end

    it "redirects to articles index for deleted articles" do
      article = create(:article, :deleted)

      get article_path(article)

      expect(response).to redirect_to(articles_path)
      expect(flash[:alert]).to include("deleted")
    end

    it "shows edit link for article owner" do
      user = create(:user)
      article = create(:article, user: user)
      sign_in user

      get article_path(article)

      expect(response.body).to include("Edit")
    end
  end

  describe "GET /articles/new" do
    context "when signed in as publisher" do
      let(:user) { create(:user) }
      let(:space) { create(:space) }

      before do
        space.add_publisher(user)
        sign_in user
      end

      it "returns http success" do
        get new_article_path
        expect(response).to have_http_status(:success)
      end

      it "displays the article form" do
        get new_article_path
        expect(response.body).to include("New Article")
      end
    end

    context "when signed in as regular user" do
      let(:user) { create(:user) }

      before { sign_in user }

      it "redirects with authorization error" do
        get new_article_path
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to be_present
      end
    end

    context "when not signed in" do
      it "redirects to sign in" do
        get new_article_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe "POST /articles" do
    let(:space) { create(:space) }

    context "when signed in as publisher" do
      let(:user) { create(:user) }

      before do
        space.add_publisher(user)
        sign_in user
      end

      context "with valid parameters" do
        let(:valid_params) do
          {
            article: {
              title: "How to Use Ruby Blocks",
              body: "This is a comprehensive guide to Ruby blocks.",
              content_type: "markdown"
            }
          }
        end

        it "creates a new article" do
          expect {
            post articles_path, params: valid_params
          }.to change(Article, :count).by(1)
        end

        it "redirects to the article" do
          post articles_path, params: valid_params
          expect(response).to redirect_to(article_path(Article.last))
        end

        it "sets the current user as author" do
          post articles_path, params: valid_params
          expect(Article.last.user).to eq(user)
        end
      end

      context "with space_ids" do
        let(:space2) { create(:space) }

        before { space2.add_publisher(user) }

        it "assigns allowed spaces to the article" do
          post articles_path, params: {
            article: {
              title: "Article with spaces",
              body: "Content",
              space_ids: [ space.id.to_s, space2.id.to_s ]
            }
          }

          expect(Article.last.spaces).to contain_exactly(space, space2)
        end

        it "filters out spaces user cannot publish to" do
          forbidden_space = create(:space)

          post articles_path, params: {
            article: {
              title: "Article with some forbidden spaces",
              body: "Content",
              space_ids: [ space.id.to_s, forbidden_space.id.to_s ]
            }
          }

          expect(Article.last.spaces).to contain_exactly(space)
          expect(Article.last.spaces).not_to include(forbidden_space)
        end
      end

      context "with invalid parameters" do
        it "does not create an article with blank title" do
          expect {
            post articles_path, params: { article: { title: "", body: "Content", content_type: "markdown" } }
          }.not_to change(Article, :count)
        end

        it "re-renders the form" do
          post articles_path, params: { article: { title: "", body: "Content", content_type: "markdown" } }
          expect(response).to have_http_status(:unprocessable_entity)
        end
      end
    end

    context "when signed in as regular user" do
      let(:user) { create(:user) }

      before { sign_in user }

      it "does not create an article" do
        expect {
          post articles_path, params: { article: { title: "Test", body: "Content", content_type: "markdown" } }
        }.not_to change(Article, :count)
      end

      it "redirects with alert" do
        post articles_path, params: { article: { title: "Test", body: "Content", content_type: "markdown" } }
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to be_present
      end
    end

    context "when not signed in" do
      it "redirects to sign in" do
        post articles_path, params: { article: { title: "Test", body: "Content", content_type: "markdown" } }
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe "GET /articles/:id/edit" do
    let(:user) { create(:user) }
    let(:article) { create(:article, user: user) }

    context "when signed in as owner" do
      before { sign_in user }

      it "returns http success" do
        get edit_article_path(article)
        expect(response).to have_http_status(:success)
      end

      it "displays the edit form" do
        get edit_article_path(article)
        expect(response.body).to include("Edit Article")
        expect(response.body).to include(article.title)
      end
    end

    context "when signed in as different user" do
      let(:other_user) { create(:user) }

      before { sign_in other_user }

      it "redirects with authorization error" do
        get edit_article_path(article)
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to be_present
      end
    end

    context "when not signed in" do
      it "redirects to sign in" do
        get edit_article_path(article)
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe "PATCH /articles/:id" do
    let(:user) { create(:user) }
    let(:article) { create(:article, user: user) }

    context "when signed in as owner" do
      before { sign_in user }

      context "with valid parameters" do
        it "updates the article" do
          patch article_path(article), params: { article: { title: "Updated title here" } }
          expect(article.reload.title).to eq("Updated title here")
        end

        it "records the edit" do
          patch article_path(article), params: { article: { title: "Updated title here" } }
          expect(article.reload.edited_at).to be_present
          expect(article.last_editor).to eq(user)
        end

        it "redirects to the article" do
          patch article_path(article), params: { article: { title: "Updated title here" } }
          expect(response).to redirect_to(article_path(article))
        end
      end

      context "with invalid parameters" do
        it "does not update the article" do
          original_title = article.title
          patch article_path(article), params: { article: { title: "" } }
          expect(article.reload.title).to eq(original_title)
        end

        it "re-renders the edit form" do
          patch article_path(article), params: { article: { title: "" } }
          expect(response).to have_http_status(:unprocessable_entity)
        end
      end

      context "with space_ids" do
        let(:space1) { create(:space) }
        let(:space2) { create(:space) }
        let(:existing_space) { create(:space) }

        before do
          space1.add_publisher(user)
          space2.add_publisher(user)
          # Add article to existing_space (user cannot modify this)
          create(:article_space, article: article, space: existing_space)
        end

        it "updates spaces the user can publish to" do
          patch article_path(article), params: {
            article: { title: "Updated", space_ids: [ space1.id.to_s, space2.id.to_s ] }
          }

          expect(article.reload.spaces).to include(space1, space2)
        end

        it "preserves spaces the user cannot modify" do
          patch article_path(article), params: {
            article: { title: "Updated", space_ids: [ space1.id.to_s ] }
          }

          # Should keep existing_space even though user didn't include it
          expect(article.reload.spaces).to include(existing_space)
        end

        it "filters out spaces user cannot publish to" do
          forbidden_space = create(:space)

          patch article_path(article), params: {
            article: { title: "Updated", space_ids: [ space1.id.to_s, forbidden_space.id.to_s ] }
          }

          expect(article.reload.spaces).to include(space1)
          expect(article.reload.spaces).not_to include(forbidden_space)
        end
      end
    end

    context "when signed in as different user" do
      let(:other_user) { create(:user) }

      before { sign_in other_user }

      it "does not update the article" do
        original_title = article.title
        patch article_path(article), params: { article: { title: "Hacked title" } }
        expect(article.reload.title).to eq(original_title)
      end

      it "redirects with alert" do
        patch article_path(article), params: { article: { title: "Hacked title" } }
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to be_present
      end
    end

    context "when not signed in" do
      it "redirects to sign in" do
        patch article_path(article), params: { article: { title: "New title" } }
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe "DELETE /articles/:id" do
    let(:user) { create(:user) }
    let!(:article) { create(:article, user: user) }

    context "when signed in as owner" do
      before { sign_in user }

      it "soft deletes the article" do
        expect {
          delete article_path(article)
        }.not_to change(Article, :count)

        expect(article.reload.deleted?).to be true
      end

      it "redirects to articles index" do
        delete article_path(article)
        expect(response).to redirect_to(articles_path)
      end
    end

    context "when signed in as different user" do
      let(:other_user) { create(:user) }

      before { sign_in other_user }

      it "does not soft delete the article" do
        delete article_path(article)
        expect(article.reload.deleted?).to be false
      end

      it "redirects with alert" do
        delete article_path(article)
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to be_present
      end
    end

    context "when not signed in" do
      it "redirects to sign in" do
        delete article_path(article)
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe "DELETE /articles/:id/hard_delete" do
    let!(:article) { create(:article) }
    let(:space) { create(:space) }

    before { create(:article_space, article: article, space: space) }

    context "when signed in as admin" do
      let(:admin) { create(:user, role: :admin) }

      before { sign_in admin }

      it "permanently deletes the article" do
        expect {
          delete hard_delete_article_path(article)
        }.to change(Article, :count).by(-1)
      end

      it "redirects to articles index" do
        delete hard_delete_article_path(article)
        expect(response).to redirect_to(articles_path)
      end
    end

    context "when signed in as space moderator" do
      let(:moderator) { create(:user) }

      before do
        space.add_moderator(moderator)
        sign_in moderator
      end

      it "permanently deletes the article" do
        expect {
          delete hard_delete_article_path(article)
        }.to change(Article, :count).by(-1)
      end
    end

    context "when signed in as regular user" do
      let(:user) { create(:user) }

      before { sign_in user }

      it "does not delete the article" do
        expect {
          delete hard_delete_article_path(article)
        }.not_to change(Article, :count)
      end

      it "redirects with alert" do
        delete hard_delete_article_path(article)
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to be_present
      end
    end

    context "when not signed in" do
      it "redirects to sign in" do
        delete hard_delete_article_path(article)
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe "GET /articles/:id (views tracking)" do
    it "increments the view count" do
      article = create(:article, views_count: 5)

      get article_path(article)

      expect(article.reload.views_count).to eq(6)
    end

    it "does not increment views for deleted articles" do
      article = create(:article, :deleted, views_count: 5)

      get article_path(article)

      expect(article.reload.views_count).to eq(5)
    end

    it "displays view count when greater than zero" do
      article = create(:article, views_count: 10)

      get article_path(article)

      expect(response.body).to include("11 views")
    end
  end

  describe "POST /articles/:id/upvote" do
    let(:article) { create(:article) }
    let(:user) { create(:user) }

    context "when signed in" do
      before { sign_in user }

      it "upvotes the article" do
        post upvote_article_path(article)

        expect(article.reload.vote_score).to eq(1)
        expect(article.upvoted_by?(user)).to be true
      end

      it "redirects to article on html request" do
        post upvote_article_path(article)

        expect(response).to redirect_to(article_path(article))
      end

      it "returns turbo_stream on turbo request" do
        post upvote_article_path(article), headers: { "Accept" => "text/vnd.turbo-stream.html" }

        expect(response.media_type).to eq("text/vnd.turbo-stream.html")
        expect(response.body).to include("article-#{article.id}-votes")
      end

      it "does not create duplicate votes" do
        article.upvote_by(user)

        post upvote_article_path(article)

        expect(article.reload.vote_score).to eq(1)
      end
    end

    context "when not signed in" do
      it "redirects to sign in" do
        post upvote_article_path(article)

        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe "DELETE /articles/:id/remove_vote" do
    let(:article) { create(:article) }
    let(:user) { create(:user) }

    context "when signed in" do
      before do
        sign_in user
        article.upvote_by(user)
      end

      it "removes the vote" do
        delete remove_vote_article_path(article)

        expect(article.reload.vote_score).to eq(0)
        expect(article.upvoted_by?(user)).to be false
      end

      it "redirects to article on html request" do
        delete remove_vote_article_path(article)

        expect(response).to redirect_to(article_path(article))
      end

      it "returns turbo_stream on turbo request" do
        delete remove_vote_article_path(article), headers: { "Accept" => "text/vnd.turbo-stream.html" }

        expect(response.media_type).to eq("text/vnd.turbo-stream.html")
      end

      it "does nothing if user has not voted" do
        article.remove_vote_by(user) # Remove existing vote first

        expect {
          delete remove_vote_article_path(article)
        }.not_to change { article.reload.vote_score }
      end
    end

    context "when not signed in" do
      it "redirects to sign in" do
        delete remove_vote_article_path(article)

        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe "POST /articles/:id/refresh_from_source" do
    let(:user) { create(:user) }
    let!(:provider) { create(:reader_provider, :enabled, api_key: "test-key") }
    let(:article) { create(:article, user: user, content_type: "webpage", source_url: "https://example.com/page", body: "Old content") }

    context "when signed in as owner" do
      before { sign_in user }

      it "refreshes content from source URL" do
        json_response = { "data" => { "content" => "# New Content\n\nUpdated from source." } }.to_json
        stub_request(:get, "https://r.jina.ai/https://example.com/page")
          .to_return(status: 200, body: json_response)

        post refresh_from_source_article_path(article)

        expect(response).to redirect_to(article_path(article))
        follow_redirect!
        expect(response.body).to include("refreshed")
        expect(article.reload.body).to eq("# New Content\n\nUpdated from source.")
      end

      it "marks article as edited" do
        json_response = { "data" => { "content" => "Updated content" } }.to_json
        stub_request(:get, "https://r.jina.ai/https://example.com/page")
          .to_return(status: 200, body: json_response)

        post refresh_from_source_article_path(article)
        expect(article.reload.edited_at).to be_present
      end

      it "shows error when fetch fails" do
        stub_request(:get, "https://r.jina.ai/https://example.com/page")
          .to_return(status: 500)

        post refresh_from_source_article_path(article)

        expect(response).to redirect_to(article_path(article))
        expect(flash[:alert]).to include("Failed")
      end

      it "prevents refresh on non-webpage article" do
        markdown_article = create(:article, user: user, content_type: "markdown")

        post refresh_from_source_article_path(markdown_article)

        expect(response).to redirect_to(article_path(markdown_article))
        expect(flash[:alert]).to include("does not have a web page source")
      end

      it "uses selected reader provider when specified" do
        firecrawl_provider = create(:reader_provider, :firecrawl, :enabled, api_endpoint: "http://firecrawl:3002")
        json_response = { "success" => true, "data" => { "markdown" => "# Firecrawl Content" } }.to_json
        stub_request(:post, "http://firecrawl:3002/v1/scrape")
          .to_return(status: 200, body: json_response)

        post refresh_from_source_article_path(article), params: { reader_provider_id: firecrawl_provider.id }

        expect(response).to redirect_to(article_path(article))
        expect(article.reload.body).to eq("# Firecrawl Content")
        expect(article.reader_provider).to eq(firecrawl_provider)
      end

      it "uses article's existing reader provider if no provider specified" do
        article_provider = create(:reader_provider, :enabled, api_key: "article-key", api_endpoint: "https://r.jina.ai")
        article.update!(reader_provider: article_provider)
        json_response = { "data" => { "content" => "# Content from article provider" } }.to_json
        stub_request(:get, "https://r.jina.ai/https://example.com/page")
          .with(headers: { "Authorization" => "Bearer article-key" })
          .to_return(status: 200, body: json_response)

        post refresh_from_source_article_path(article)

        expect(response).to redirect_to(article_path(article))
        expect(article.reload.body).to eq("# Content from article provider")
      end
    end

    context "when signed in as different user" do
      let(:other_user) { create(:user) }

      before { sign_in other_user }

      it "does not allow refresh" do
        stub_request(:get, "https://r.jina.ai/https://example.com/page")
          .to_return(status: 200, body: "New content")

        post refresh_from_source_article_path(article)

        expect(response).to redirect_to(root_path)
        expect(article.reload.body).to eq("Old content")
      end
    end

    context "when not signed in" do
      it "redirects to sign in" do
        post refresh_from_source_article_path(article)

        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe "webpage article creation" do
    let(:user) { create(:user, :admin) }
    let!(:provider) { create(:reader_provider, :enabled, api_key: "test-key") }

    before { sign_in user }

    it "creates article from webpage URL" do
      json_response = { "data" => { "content" => "# Article Title\n\nArticle content here." } }.to_json
      stub_request(:get, "https://r.jina.ai/https://example.com/article")
        .to_return(status: 200, body: json_response)

      expect {
        post articles_path, params: {
          article: {
            title: "Imported Article",
            input_mode: "webpage",
            source_url: "https://example.com/article"
          }
        }
      }.to change(Article, :count).by(1)

      article = Article.last
      expect(article.content_type).to eq("webpage")
      expect(article.source_url).to eq("https://example.com/article")
      expect(article.body).to include("Article content")
    end

    it "shows error when fetch fails during creation" do
      stub_request(:get, "https://r.jina.ai/https://example.com/article")
        .to_return(status: 404)

      expect {
        post articles_path, params: {
          article: {
            title: "Imported Article",
            input_mode: "webpage",
            source_url: "https://example.com/article"
          }
        }
      }.not_to change(Article, :count)

      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "shows error when source_url is missing" do
      expect {
        post articles_path, params: {
          article: {
            title: "Imported Article",
            input_mode: "webpage",
            source_url: ""
          }
        }
      }.not_to change(Article, :count)

      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "uses selected reader provider when specified" do
      firecrawl_provider = create(:reader_provider, :firecrawl, api_endpoint: "http://firecrawl:3002")
      json_response = { "success" => true, "data" => { "markdown" => "# Firecrawl Article" } }.to_json
      stub_request(:post, "http://firecrawl:3002/v1/scrape")
        .to_return(status: 200, body: json_response)

      expect {
        post articles_path, params: {
          article: {
            title: "Firecrawl Imported Article",
            input_mode: "webpage",
            source_url: "https://example.com/firecrawl-article",
            reader_provider_id: firecrawl_provider.id
          }
        }
      }.to change(Article, :count).by(1)

      article = Article.last
      expect(article.content_type).to eq("webpage")
      expect(article.reader_provider).to eq(firecrawl_provider)
      expect(article.body).to include("Firecrawl Article")
    end
  end
end
