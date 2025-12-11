# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Admin::SearchSettings", type: :request do
  let(:admin) { create(:user, :admin) }
  let(:regular_user) { create(:user) }

  describe "GET /admin/search_settings" do
    context "when not logged in" do
      it "redirects to root" do
        get admin_search_settings_path
        expect(response).to redirect_to(root_path)
      end
    end

    context "when logged in as regular user" do
      before { sign_in regular_user }

      it "redirects to root with alert" do
        get admin_search_settings_path
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to eq("You must be an admin to access this area.")
      end
    end

    context "when logged in as admin" do
      before { sign_in admin }

      it "returns http success" do
        get admin_search_settings_path
        expect(response).to have_http_status(:success)
      end

      it "displays search settings form" do
        get admin_search_settings_path
        expect(response.body).to include("Search Settings")
        expect(response.body).to include("RAG")
      end

      it "displays the current rag_chunk_limit value" do
        SearchSetting.rag_chunk_limit = 15
        get admin_search_settings_path
        expect(response.body).to include("15")
      end

      it "displays the current similar_questions_limit value" do
        SearchSetting.similar_questions_limit = 5
        get admin_search_settings_path
        expect(response.body).to include("5")
      end
    end
  end

  describe "PATCH /admin/search_settings" do
    context "when not logged in" do
      it "redirects to root" do
        patch admin_search_settings_path, params: { rag_chunk_limit: 20 }
        expect(response).to redirect_to(root_path)
      end
    end

    context "when logged in as regular user" do
      before { sign_in regular_user }

      it "redirects to root with alert" do
        patch admin_search_settings_path, params: { rag_chunk_limit: 20 }
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to eq("You must be an admin to access this area.")
      end
    end

    context "when logged in as admin" do
      before { sign_in admin }

      it "updates rag_chunk_limit" do
        patch admin_search_settings_path, params: { rag_chunk_limit: 25, similar_questions_limit: 3 }

        expect(SearchSetting.rag_chunk_limit).to eq(25)
      end

      it "updates similar_questions_limit" do
        patch admin_search_settings_path, params: { rag_chunk_limit: 10, similar_questions_limit: 5 }

        expect(SearchSetting.similar_questions_limit).to eq(5)
      end

      it "redirects with success notice" do
        patch admin_search_settings_path, params: { rag_chunk_limit: 20, similar_questions_limit: 3 }

        expect(response).to redirect_to(admin_search_settings_path)
        expect(flash[:notice]).to include("Search settings updated")
      end
    end
  end
end
