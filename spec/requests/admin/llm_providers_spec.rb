# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Admin::LlmProviders" do
  let(:admin) { create(:user, :admin) }
  let(:user) { create(:user) }

  describe "GET /admin/llm_providers" do
    context "when not logged in" do
      it "redirects to root" do
        get admin_llm_providers_path
        expect(response).to redirect_to(root_path)
      end
    end

    context "when logged in as regular user" do
      before { sign_in user }

      it "redirects to root with alert" do
        get admin_llm_providers_path
        expect(response).to redirect_to(root_path)
      end
    end

    context "when logged in as admin" do
      before { sign_in admin }

      it "returns http success" do
        get admin_llm_providers_path
        expect(response).to have_http_status(:success)
      end

      it "displays llm providers" do
        provider = create(:llm_provider, :openai, name: "My GPT-4")
        get admin_llm_providers_path
        expect(response.body).to include("My GPT-4")
        expect(response.body).to include("OpenAI")
      end
    end
  end

  describe "GET /admin/llm_providers/:id" do
    let!(:provider) { create(:llm_provider, :openai) }

    before { sign_in admin }

    it "returns http success" do
      get admin_llm_provider_path(provider)
      expect(response).to have_http_status(:success)
    end

    it "displays provider details" do
      get admin_llm_provider_path(provider)
      expect(response.body).to include(provider.name)
      expect(response.body).to include(provider.llm_model)
    end
  end

  describe "GET /admin/llm_providers/new" do
    before { sign_in admin }

    it "returns http success without provider_type" do
      get new_admin_llm_provider_path
      expect(response).to have_http_status(:success)
    end

    it "returns http success with provider_type" do
      get new_admin_llm_provider_path(provider_type: "openai")
      expect(response).to have_http_status(:success)
    end

    it "applies defaults from provider_type parameter" do
      get new_admin_llm_provider_path(provider_type: "anthropic")
      expect(response).to have_http_status(:success)
      expect(response.body).to include("claude")
    end
  end

  describe "POST /admin/llm_providers" do
    before { sign_in admin }

    context "with valid params" do
      let(:valid_params) do
        {
          llm_provider: {
            name: "Test Provider",
            provider_type: "openai",
            llm_model: "gpt-4o",
            api_key: "sk-test-key"
          }
        }
      end

      it "creates a new llm provider" do
        expect {
          post admin_llm_providers_path, params: valid_params
        }.to change(LlmProvider, :count).by(1)
      end

      it "redirects to the show page" do
        post admin_llm_providers_path, params: valid_params
        expect(response).to redirect_to(admin_llm_provider_path(LlmProvider.last))
      end
    end

    context "with invalid params" do
      let(:invalid_params) do
        {
          llm_provider: {
            name: "",
            provider_type: "invalid"
          }
        }
      end

      it "does not create a provider" do
        expect {
          post admin_llm_providers_path, params: invalid_params
        }.not_to change(LlmProvider, :count)
      end

      it "renders the new form" do
        post admin_llm_providers_path, params: invalid_params
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe "GET /admin/llm_providers/:id/edit" do
    let!(:provider) { create(:llm_provider, :openai) }

    before { sign_in admin }

    it "returns http success" do
      get edit_admin_llm_provider_path(provider)
      expect(response).to have_http_status(:success)
    end
  end

  describe "PATCH /admin/llm_providers/:id" do
    let!(:provider) { create(:llm_provider, :openai, api_key: "original-key") }

    before { sign_in admin }

    context "with valid params" do
      it "updates the provider" do
        patch admin_llm_provider_path(provider), params: {
          llm_provider: { name: "Updated Name" }
        }
        expect(provider.reload.name).to eq("Updated Name")
      end

      it "redirects to the show page" do
        patch admin_llm_provider_path(provider), params: {
          llm_provider: { name: "Updated Name" }
        }
        expect(response).to redirect_to(admin_llm_provider_path(provider))
      end

      it "preserves API key when blank" do
        patch admin_llm_provider_path(provider), params: {
          llm_provider: { name: "Updated Name", api_key: "" }
        }
        expect(provider.reload.api_key).to eq("original-key")
      end

      it "updates API key when provided" do
        patch admin_llm_provider_path(provider), params: {
          llm_provider: { api_key: "new-key" }
        }
        expect(provider.reload.api_key).to eq("new-key")
      end
    end

    context "with invalid params" do
      it "does not update the provider" do
        patch admin_llm_provider_path(provider), params: {
          llm_provider: { name: "" }
        }
        expect(provider.reload.name).not_to eq("")
      end

      it "renders the edit form" do
        patch admin_llm_provider_path(provider), params: {
          llm_provider: { name: "" }
        }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe "DELETE /admin/llm_providers/:id" do
    before { sign_in admin }

    context "when provider is not enabled" do
      let!(:enabled_provider) { create(:llm_provider, :openai) } # First one - auto-enabled
      let!(:disabled_provider) { create(:llm_provider, :anthropic) } # Second one - not enabled

      it "destroys the provider" do
        expect {
          delete admin_llm_provider_path(disabled_provider)
        }.to change(LlmProvider, :count).by(-1)
      end

      it "redirects to the index" do
        delete admin_llm_provider_path(disabled_provider)
        expect(response).to redirect_to(admin_llm_providers_path)
      end
    end

    context "when provider is enabled" do
      let!(:provider) { create(:llm_provider, :openai) } # Auto-enabled as first

      it "does not destroy the provider" do
        expect {
          delete admin_llm_provider_path(provider)
        }.not_to change(LlmProvider, :count)
      end

      it "redirects with an alert" do
        delete admin_llm_provider_path(provider)
        expect(response).to redirect_to(admin_llm_providers_path)
        expect(flash[:alert]).to include("Cannot delete")
      end
    end
  end

  describe "POST /admin/llm_providers/:id/activate" do
    before { sign_in admin }

    let!(:first_provider) { create(:llm_provider, :openai) } # Auto-enabled
    let!(:second_provider) { create(:llm_provider, :anthropic) } # Not enabled

    it "toggles the provider's enabled status" do
      expect(second_provider.enabled?).to be false
      post activate_admin_llm_provider_path(second_provider)
      expect(second_provider.reload.enabled?).to be true
    end

    it "redirects to the index with notice" do
      post activate_admin_llm_provider_path(second_provider)
      expect(response).to redirect_to(admin_llm_providers_path)
      expect(flash[:notice]).to include("is now enabled")
    end

    it "can disable an enabled provider" do
      post activate_admin_llm_provider_path(first_provider)
      expect(first_provider.reload.enabled?).to be false
    end
  end

  describe "POST /admin/llm_providers/:id/set_default" do
    before { sign_in admin }

    let!(:first_provider) { create(:llm_provider, :openai) } # Auto-enabled and default
    let!(:second_provider) { create(:llm_provider, :anthropic) } # Not enabled

    it "sets the provider as default" do
      post set_default_admin_llm_provider_path(second_provider)
      expect(second_provider.reload.is_default?).to be true
    end

    it "enables the provider" do
      expect(second_provider.enabled?).to be false
      post set_default_admin_llm_provider_path(second_provider)
      expect(second_provider.reload.enabled?).to be true
    end

    it "removes default from other providers" do
      post set_default_admin_llm_provider_path(second_provider)
      expect(first_provider.reload.is_default?).to be false
    end

    it "redirects with notice" do
      post set_default_admin_llm_provider_path(second_provider)
      expect(response).to redirect_to(admin_llm_providers_path)
      expect(flash[:notice]).to include("is now the default")
    end
  end

  describe "GET /admin/llm_providers/ollama_models" do
    before { sign_in admin }

    context "without endpoint parameter (auto-detect)" do
      it "returns detected endpoint and models when Ollama found" do
        stub_request(:get, "http://host.docker.internal:11434/api/tags")
          .to_return(
            status: 200,
            body: { models: [ { name: "llama3.2:latest", details: { parameter_size: "3B" } } ] }.to_json
          )

        get ollama_models_admin_llm_providers_path

        expect(response).to have_http_status(:success)
        json = JSON.parse(response.body)
        expect(json["endpoint"]).to eq("http://host.docker.internal:11434")
        expect(json["models"].first["name"]).to eq("llama3.2:latest")
      end

      it "returns 404 when no Ollama instance found" do
        OllamaDiscoveryService::DEFAULT_ENDPOINTS.each do |endpoint|
          stub_request(:get, "#{endpoint}/api/tags")
            .to_raise(Errno::ECONNREFUSED)
        end

        get ollama_models_admin_llm_providers_path

        expect(response).to have_http_status(:not_found)
        json = JSON.parse(response.body)
        expect(json["error"]).to include("No Ollama instance found")
      end
    end

    context "with endpoint parameter" do
      it "returns models from specified endpoint" do
        stub_request(:get, "http://custom-host:11434/api/tags")
          .to_return(
            status: 200,
            body: { models: [ { name: "mistral:7b" } ] }.to_json
          )

        get ollama_models_admin_llm_providers_path(endpoint: "http://custom-host:11434")

        expect(response).to have_http_status(:success)
        json = JSON.parse(response.body)
        expect(json["models"].first["name"]).to eq("mistral:7b")
      end

      it "returns 400 when endpoint unreachable" do
        stub_request(:get, "http://bad-host:11434/api/tags")
          .to_raise(Errno::ECONNREFUSED)

        get ollama_models_admin_llm_providers_path(endpoint: "http://bad-host:11434")

        expect(response).to have_http_status(:bad_request)
        json = JSON.parse(response.body)
        expect(json["error"]).to include("Cannot connect")
      end

      it "returns 400 when OllamaDiscoveryService raises an error" do
        allow(OllamaDiscoveryService).to receive(:reachable?).and_raise(OllamaDiscoveryService::Error.new("Test error"))

        get ollama_models_admin_llm_providers_path(endpoint: "http://custom-host:11434")

        expect(response).to have_http_status(:bad_request)
        json = JSON.parse(response.body)
        expect(json["error"]).to eq("Test error")
      end
    end

    context "when not logged in" do
      before { sign_out admin }

      it "redirects to root" do
        get ollama_models_admin_llm_providers_path
        expect(response).to redirect_to(root_path)
      end
    end
  end
end
