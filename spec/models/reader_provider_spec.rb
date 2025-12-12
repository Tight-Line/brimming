# frozen_string_literal: true

require "rails_helper"

RSpec.describe ReaderProvider, type: :model do
  describe "validations" do
    subject { build(:reader_provider) }

    it { should validate_presence_of(:name) }
    it { should validate_uniqueness_of(:name) }
    it { should validate_presence_of(:provider_type) }
    it { should validate_inclusion_of(:provider_type).in_array(ReaderProvider::PROVIDER_TYPES) }

    describe "api_endpoint validation" do
      it "accepts valid HTTP URL" do
        provider = build(:reader_provider, api_endpoint: "http://example.com")
        expect(provider).to be_valid
      end

      it "accepts valid HTTPS URL" do
        provider = build(:reader_provider, api_endpoint: "https://example.com")
        expect(provider).to be_valid
      end

      it "rejects non-HTTP URLs" do
        provider = build(:reader_provider, api_endpoint: "ftp://example.com")
        expect(provider).not_to be_valid
        expect(provider.errors[:api_endpoint]).to include("must be a valid HTTP or HTTPS URL")
      end

      it "rejects invalid URLs" do
        provider = build(:reader_provider, api_endpoint: "not a url at all")
        expect(provider).not_to be_valid
        expect(provider.errors[:api_endpoint]).to include("must be a valid URL")
      end

      it "skips validation when api_endpoint is blank" do
        provider = build(:reader_provider)
        # Set api_endpoint to nil and call validation method directly to bypass callback
        provider.api_endpoint = nil
        provider.send(:api_endpoint_is_valid_url)
        # No errors should be added when blank
        expect(provider.errors[:api_endpoint]).to be_empty
      end
    end
  end

  describe "scopes" do
    describe ".enabled" do
      it "returns only enabled providers" do
        enabled = create(:reader_provider, :enabled)
        _disabled = create(:reader_provider, enabled: false)

        expect(ReaderProvider.enabled).to eq([ enabled ])
      end
    end
  end

  describe "encryption" do
    it "encrypts api_key" do
      provider = create(:reader_provider, api_key: "secret-key")

      # Verify encryption by checking the raw database value
      raw_value = ActiveRecord::Base.connection.select_value(
        "SELECT api_key FROM reader_providers WHERE id = #{provider.id}"
      )

      expect(raw_value).not_to eq("secret-key")
      expect(provider.reload.api_key).to eq("secret-key")
    end
  end

  describe "#display_provider_type" do
    it "returns 'Jina.ai Reader' for jina type" do
      provider = build(:reader_provider, provider_type: "jina")
      expect(provider.display_provider_type).to eq("Jina.ai Reader")
    end

    it "returns 'Firecrawl' for firecrawl type" do
      provider = build(:reader_provider, provider_type: "firecrawl")
      expect(provider.display_provider_type).to eq("Firecrawl")
    end

    it "returns 'Not Selected' for nil type" do
      provider = build(:reader_provider)
      provider.provider_type = nil
      expect(provider.display_provider_type).to eq("Not Selected")
    end

    it "returns 'Not Selected' for empty type" do
      provider = build(:reader_provider)
      provider.provider_type = ""
      expect(provider.display_provider_type).to eq("Not Selected")
    end

    it "returns titleized name for unknown type" do
      provider = build(:reader_provider)
      provider.provider_type = "some_future_provider"
      expect(provider.display_provider_type).to eq("Some Future Provider")
    end
  end

  describe "#requires_api_key?" do
    it "returns true for jina provider" do
      provider = build(:reader_provider, provider_type: "jina")
      expect(provider.requires_api_key?).to be true
    end

    it "returns false for firecrawl provider" do
      provider = build(:reader_provider, provider_type: "firecrawl")
      expect(provider.requires_api_key?).to be false
    end
  end

  describe "#can_delete?" do
    it "returns true when not enabled" do
      provider = build(:reader_provider, enabled: false)
      expect(provider.can_delete?).to be true
    end

    it "returns false when enabled" do
      provider = build(:reader_provider, enabled: true)
      expect(provider.can_delete?).to be false
    end
  end

  describe ".available?" do
    it "returns true when an enabled provider exists" do
      create(:reader_provider, :enabled)
      expect(ReaderProvider.available?).to be true
    end

    it "returns false when no enabled provider exists" do
      # Create first provider (auto-enables), then create another and disable the first
      first = create(:reader_provider)
      _second = create(:reader_provider)
      first.update_column(:enabled, false)
      ReaderProvider.where.not(id: [ first.id ]).update_all(enabled: false)

      expect(ReaderProvider.available?).to be false
    end

    it "returns false when no providers exist" do
      expect(ReaderProvider.available?).to be false
    end
  end

  describe ".enabled_provider" do
    it "returns the first enabled provider" do
      # First provider is auto-enabled, second is created disabled
      first = create(:reader_provider)
      _second = create(:reader_provider)
      # Disable first, enable second explicitly
      first.update_column(:enabled, false)

      enabled = create(:reader_provider, :enabled)

      expect(ReaderProvider.enabled_provider).to eq(enabled)
    end

    it "returns nil when no enabled provider exists" do
      # Create two providers to avoid auto-enable, then disable both
      first = create(:reader_provider)
      second = create(:reader_provider)
      first.update_column(:enabled, false)
      second.update_column(:enabled, false)

      expect(ReaderProvider.enabled_provider).to be_nil
    end
  end

  describe "callbacks" do
    describe "set_default_api_endpoint" do
      it "sets default endpoint for jina provider" do
        provider = ReaderProvider.new(name: "Test", provider_type: "jina")
        provider.valid?

        expect(provider.api_endpoint).to eq("https://r.jina.ai")
      end

      it "sets default endpoint for firecrawl provider" do
        provider = ReaderProvider.new(name: "Test", provider_type: "firecrawl")
        provider.valid?

        expect(provider.api_endpoint).to eq("http://firecrawl:3002")
      end

      it "does not override existing endpoint" do
        provider = ReaderProvider.new(
          name: "Test",
          provider_type: "jina",
          api_endpoint: "https://custom.jina.ai"
        )
        provider.valid?

        expect(provider.api_endpoint).to eq("https://custom.jina.ai")
      end
    end

    describe "enable_if_first" do
      it "auto-enables the first provider" do
        provider = create(:reader_provider, enabled: false)
        expect(provider.reload.enabled).to be true
      end

      it "does not auto-enable subsequent providers" do
        _first = create(:reader_provider)
        second = create(:reader_provider, enabled: false)

        expect(second.reload.enabled).to be false
      end
    end
  end
end
