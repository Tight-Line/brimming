# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Admin::EmbeddingProviders" do
  let(:admin) { create(:user, :admin) }
  let(:user) { create(:user) }

  describe "GET /admin/embedding_providers" do
    context "when not logged in" do
      it "redirects to root" do
        get admin_embedding_providers_path
        expect(response).to redirect_to(root_path)
      end
    end

    context "when logged in as regular user" do
      before { sign_in user }

      it "redirects to root with alert" do
        get admin_embedding_providers_path
        expect(response).to redirect_to(root_path)
      end
    end

    context "when logged in as admin" do
      before { sign_in admin }

      it "returns http success" do
        get admin_embedding_providers_path
        expect(response).to have_http_status(:success)
      end

      it "displays embedding providers" do
        provider = create(:embedding_provider, :openai, name: "My OpenAI")
        get admin_embedding_providers_path
        expect(response.body).to include("My OpenAI")
        expect(response.body).to include("OpenAI")
      end
    end
  end

  describe "GET /admin/embedding_providers/:id" do
    let!(:provider) { create(:embedding_provider, :openai) }

    before { sign_in admin }

    it "returns http success" do
      get admin_embedding_provider_path(provider)
      expect(response).to have_http_status(:success)
    end

    it "displays provider details" do
      get admin_embedding_provider_path(provider)
      expect(response.body).to include(provider.name)
      expect(response.body).to include(provider.embedding_model)
    end
  end

  describe "GET /admin/embedding_providers/new" do
    before { sign_in admin }

    it "returns http success without provider_type" do
      get new_admin_embedding_provider_path
      expect(response).to have_http_status(:success)
    end

    it "returns http success with provider_type" do
      get new_admin_embedding_provider_path(provider_type: "openai")
      expect(response).to have_http_status(:success)
    end

    it "applies defaults from provider_type parameter" do
      get new_admin_embedding_provider_path(provider_type: "cohere")
      expect(response).to have_http_status(:success)
      expect(response.body).to include("embed-english-v3.0")
    end
  end

  describe "POST /admin/embedding_providers" do
    before { sign_in admin }

    context "with valid params" do
      let(:valid_params) do
        {
          embedding_provider: {
            name: "Test Provider",
            provider_type: "openai",
            embedding_model: "text-embedding-3-small",
            dimensions: 1536,
            api_key: "sk-test-key",
            enabled: false
          }
        }
      end

      it "creates a new embedding provider" do
        expect {
          post admin_embedding_providers_path, params: valid_params
        }.to change(EmbeddingProvider, :count).by(1)
      end

      it "redirects to the show page" do
        post admin_embedding_providers_path, params: valid_params
        expect(response).to redirect_to(admin_embedding_provider_path(EmbeddingProvider.last))
      end
    end

    context "with invalid params" do
      let(:invalid_params) do
        {
          embedding_provider: {
            name: "",
            provider_type: "invalid"
          }
        }
      end

      it "does not create a provider" do
        expect {
          post admin_embedding_providers_path, params: invalid_params
        }.not_to change(EmbeddingProvider, :count)
      end

      it "renders the new form" do
        post admin_embedding_providers_path, params: invalid_params
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe "GET /admin/embedding_providers/:id/edit" do
    let!(:provider) { create(:embedding_provider, :openai) }

    before { sign_in admin }

    it "returns http success" do
      get edit_admin_embedding_provider_path(provider)
      expect(response).to have_http_status(:success)
    end
  end

  describe "PATCH /admin/embedding_providers/:id" do
    let!(:provider) { create(:embedding_provider, :openai, api_key: "original-key") }

    before { sign_in admin }

    context "with valid params" do
      it "updates the provider" do
        patch admin_embedding_provider_path(provider), params: {
          embedding_provider: { name: "Updated Name" }
        }
        expect(provider.reload.name).to eq("Updated Name")
      end

      it "redirects to the show page" do
        patch admin_embedding_provider_path(provider), params: {
          embedding_provider: { name: "Updated Name" }
        }
        expect(response).to redirect_to(admin_embedding_provider_path(provider))
      end

      it "preserves API key when blank" do
        patch admin_embedding_provider_path(provider), params: {
          embedding_provider: { name: "Updated Name", api_key: "" }
        }
        expect(provider.reload.api_key).to eq("original-key")
      end

      it "updates API key when provided" do
        patch admin_embedding_provider_path(provider), params: {
          embedding_provider: { api_key: "new-key" }
        }
        expect(provider.reload.api_key).to eq("new-key")
      end
    end

    context "with invalid params" do
      it "does not update the provider" do
        patch admin_embedding_provider_path(provider), params: {
          embedding_provider: { name: "" }
        }
        expect(provider.reload.name).not_to eq("")
      end

      it "renders the edit form" do
        patch admin_embedding_provider_path(provider), params: {
          embedding_provider: { name: "" }
        }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe "DELETE /admin/embedding_providers/:id" do
    before { sign_in admin }

    context "when provider is not active" do
      let!(:active_provider) { create(:embedding_provider, :openai) } # First one - auto-enabled
      let!(:inactive_provider) { create(:embedding_provider, :cohere) } # Second one - not enabled

      it "destroys the provider" do
        expect {
          delete admin_embedding_provider_path(inactive_provider)
        }.to change(EmbeddingProvider, :count).by(-1)
      end

      it "redirects to the index" do
        delete admin_embedding_provider_path(inactive_provider)
        expect(response).to redirect_to(admin_embedding_providers_path)
      end
    end

    context "when provider is active" do
      let!(:provider) { create(:embedding_provider, :openai) } # Auto-enabled as first

      it "does not destroy the provider" do
        expect {
          delete admin_embedding_provider_path(provider)
        }.not_to change(EmbeddingProvider, :count)
      end

      it "redirects with an alert" do
        delete admin_embedding_provider_path(provider)
        expect(response).to redirect_to(admin_embedding_providers_path)
        expect(flash[:alert]).to include("Cannot delete")
      end
    end
  end

  describe "POST /admin/embedding_providers/:id/activate" do
    before { sign_in admin }

    let!(:first_provider) { create(:embedding_provider, :openai) } # Auto-enabled
    let!(:second_provider) { create(:embedding_provider, :cohere) } # Not enabled

    it "activates the provider and deactivates others" do
      post activate_admin_embedding_provider_path(second_provider)
      expect(first_provider.reload.enabled).to be false
      expect(second_provider.reload.enabled).to be true
    end

    it "redirects to the index with notice" do
      post activate_admin_embedding_provider_path(second_provider)
      expect(response).to redirect_to(admin_embedding_providers_path)
      expect(flash[:notice]).to include("is now active")
    end

    context "when activating already active provider" do
      it "shows already active message" do
        post activate_admin_embedding_provider_path(first_provider)
        expect(response).to redirect_to(admin_embedding_providers_path)
        expect(flash[:notice]).to include("is now active")
      end
    end

    context "when existing embeddings need re-generation" do
      let(:space) { create(:space) }
      let!(:question_with_embedding) do
        q = create(:question, space: space, user: admin)
        q.update_columns(
          embedding: Array.new(1536) { rand },
          embedded_at: Time.current,
          embedding_provider_id: first_provider.id
        )
        q
      end

      it "mentions re-embedding in the notice" do
        post activate_admin_embedding_provider_path(second_provider)
        expect(flash[:notice]).to include("Re-embedding")
      end
    end

    context "when no existing embeddings" do
      it "mentions embedding in the notice" do
        # Second provider means it's a new switch
        post activate_admin_embedding_provider_path(second_provider)
        expect(flash[:notice]).to include("Embedding")
      end
    end
  end

  describe "POST /admin/embedding_providers/:id/reindex" do
    before { sign_in admin }

    let!(:active_provider) { create(:embedding_provider, :openai) } # Auto-enabled
    let!(:inactive_provider) { create(:embedding_provider, :cohere) }

    context "when provider is active" do
      let(:space) { create(:space) }

      it "clears existing embeddings" do
        question = create(:question, space: space, user: admin)
        question.update_columns(
          embedding: Array.new(1536) { rand },
          embedded_at: Time.current,
          embedding_provider_id: active_provider.id
        )

        post reindex_admin_embedding_provider_path(active_provider)
        expect(question.reload.embedding).to be_nil
        expect(question.embedded_at).to be_nil
      end

      it "queues regeneration job" do
        expect {
          post reindex_admin_embedding_provider_path(active_provider)
        }.to have_enqueued_job(RegenerateAllEmbeddingsJob)
      end

      it "redirects with notice" do
        post reindex_admin_embedding_provider_path(active_provider)
        expect(response).to redirect_to(admin_embedding_providers_path)
        expect(flash[:notice]).to include("Reindexing started")
      end

      context "with pending embedding jobs in queue" do
        it "clears pending GenerateQuestionEmbeddingJob jobs" do
          mock_queue = instance_double(Sidekiq::Queue)
          embedding_job = double("Sidekiq::Job", klass: "GenerateQuestionEmbeddingJob")
          other_job = double("Sidekiq::Job", klass: "OtherJob")

          allow(Sidekiq::Queue).to receive(:new).with("embeddings").and_return(mock_queue)
          allow(mock_queue).to receive(:each).and_yield(embedding_job).and_yield(other_job)

          expect(embedding_job).to receive(:delete)
          expect(other_job).not_to receive(:delete)

          post reindex_admin_embedding_provider_path(active_provider)
        end
      end
    end

    context "when provider is not active" do
      it "does not allow reindex" do
        post reindex_admin_embedding_provider_path(inactive_provider)
        expect(response).to redirect_to(admin_embedding_providers_path)
        expect(flash[:alert]).to include("only reindex the active")
      end
    end
  end
end
