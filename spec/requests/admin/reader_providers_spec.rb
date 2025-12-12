# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Admin::ReaderProviders", type: :request do
  let(:admin) { create(:user, :admin) }
  let(:user) { create(:user) }

  describe "GET /admin/reader_providers" do
    it "requires admin login" do
      sign_in user
      get admin_reader_providers_path
      expect(response).to redirect_to(root_path)
    end

    it "lists reader providers for admin" do
      sign_in admin
      provider = create(:reader_provider, name: "Test Jina")

      get admin_reader_providers_path

      expect(response).to be_successful
      expect(response.body).to include("Test Jina")
    end
  end

  describe "GET /admin/reader_providers/new" do
    before { sign_in admin }

    it "shows the new provider form" do
      get new_admin_reader_provider_path(provider_type: "jina")

      expect(response).to be_successful
      expect(response.body).to include("Jina.ai Reader")
    end

    it "pre-fills defaults for provider type" do
      get new_admin_reader_provider_path(provider_type: "jina")

      expect(response.body).to include("https://r.jina.ai")
    end

    it "shows form without defaults when provider_type not specified" do
      get new_admin_reader_provider_path

      expect(response).to be_successful
      expect(response.body).to include("New Reader Provider")
    end
  end

  describe "POST /admin/reader_providers" do
    before { sign_in admin }

    it "creates a new provider" do
      expect {
        post admin_reader_providers_path, params: {
          reader_provider: {
            name: "Production Jina",
            provider_type: "jina",
            api_key: "secret-key",
            api_endpoint: "https://r.jina.ai"
          }
        }
      }.to change(ReaderProvider, :count).by(1)

      expect(response).to redirect_to(admin_reader_providers_path)
    end

    it "renders errors on invalid input" do
      post admin_reader_providers_path, params: {
        reader_provider: {
          name: "",
          provider_type: "jina"
        }
      }

      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "GET /admin/reader_providers/:id/edit" do
    before { sign_in admin }

    it "shows the edit form" do
      provider = create(:reader_provider, name: "Test Provider")

      get edit_admin_reader_provider_path(provider)

      expect(response).to be_successful
      expect(response.body).to include("Test Provider")
    end
  end

  describe "PATCH /admin/reader_providers/:id" do
    before { sign_in admin }

    let!(:provider) { create(:reader_provider, name: "Old Name", api_key: "old-key") }

    it "updates the provider" do
      patch admin_reader_provider_path(provider), params: {
        reader_provider: { name: "New Name" }
      }

      expect(response).to redirect_to(admin_reader_providers_path)
      expect(provider.reload.name).to eq("New Name")
    end

    it "preserves API key if blank in params" do
      patch admin_reader_provider_path(provider), params: {
        reader_provider: { name: "New Name", api_key: "" }
      }

      expect(provider.reload.api_key).to eq("old-key")
    end

    it "updates API key if provided" do
      patch admin_reader_provider_path(provider), params: {
        reader_provider: { api_key: "new-key" }
      }

      expect(provider.reload.api_key).to eq("new-key")
    end

    it "renders errors on invalid input" do
      patch admin_reader_provider_path(provider), params: {
        reader_provider: { name: "" }
      }

      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "DELETE /admin/reader_providers/:id" do
    before { sign_in admin }

    it "deletes a disabled provider" do
      provider = create(:reader_provider, enabled: false)
      # Create another so the first doesn't auto-enable
      create(:reader_provider, enabled: true)
      provider.update_column(:enabled, false)

      expect {
        delete admin_reader_provider_path(provider)
      }.to change(ReaderProvider, :count).by(-1)

      expect(response).to redirect_to(admin_reader_providers_path)
    end

    it "prevents deletion of enabled provider" do
      provider = create(:reader_provider, :enabled)

      delete admin_reader_provider_path(provider)

      expect(response).to redirect_to(admin_reader_providers_path)
      expect(flash[:alert]).to include("Cannot delete")
      expect(provider.reload).to be_persisted
    end
  end

  describe "POST /admin/reader_providers/:id/activate" do
    before { sign_in admin }

    it "activates the provider" do
      # Create two providers so the first doesn't auto-enable
      _first = create(:reader_provider, :enabled)
      provider = create(:reader_provider, enabled: false)

      post activate_admin_reader_provider_path(provider)

      expect(response).to redirect_to(admin_reader_providers_path)
      expect(provider.reload.enabled).to be true
    end

    it "disables other providers when activating" do
      first = create(:reader_provider, :enabled)
      second = create(:reader_provider, enabled: false)

      post activate_admin_reader_provider_path(second)

      expect(first.reload.enabled).to be false
      expect(second.reload.enabled).to be true
    end
  end
end
