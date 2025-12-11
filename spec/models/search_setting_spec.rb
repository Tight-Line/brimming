# frozen_string_literal: true

require "rails_helper"

RSpec.describe SearchSetting, type: :model do
  describe "validations" do
    subject { build(:search_setting) }

    it { is_expected.to validate_presence_of(:key) }
    it { is_expected.to validate_uniqueness_of(:key) }
    it { is_expected.to validate_presence_of(:value) }
  end

  describe "DEFAULTS" do
    it "includes rag_chunk_limit with default of 10" do
      expect(described_class::DEFAULTS["rag_chunk_limit"]).to eq(10)
    end

    it "includes similar_questions_limit with default of 3" do
      expect(described_class::DEFAULTS["similar_questions_limit"]).to eq(3)
    end
  end

  describe ".get" do
    context "when setting exists" do
      before { create(:search_setting, key: "test_key", value: "custom_value") }

      it "returns the stored value" do
        expect(described_class.get("test_key")).to eq("custom_value")
      end
    end

    context "when setting does not exist but has default" do
      it "returns the default value" do
        expect(described_class.get("rag_chunk_limit")).to eq(10)
      end
    end

    context "when setting does not exist and has no default" do
      it "returns nil" do
        expect(described_class.get("unknown_key")).to be_nil
      end
    end
  end

  describe ".set" do
    context "when setting does not exist" do
      it "creates a new setting" do
        expect {
          described_class.set("new_key", "new_value", description: "A new setting")
        }.to change(described_class, :count).by(1)
      end

      it "stores the value" do
        described_class.set("new_key", "new_value")
        expect(described_class.get("new_key")).to eq("new_value")
      end

      it "stores the description" do
        described_class.set("new_key", "new_value", description: "A new setting")
        expect(described_class.find_by(key: "new_key").description).to eq("A new setting")
      end
    end

    context "when setting already exists" do
      before { create(:search_setting, key: "existing_key", value: "old_value", description: "Old description") }

      it "updates the value" do
        described_class.set("existing_key", "updated_value")
        expect(described_class.get("existing_key")).to eq("updated_value")
      end

      it "does not create a new record" do
        expect {
          described_class.set("existing_key", "updated_value")
        }.not_to change(described_class, :count)
      end

      it "updates the description if provided" do
        described_class.set("existing_key", "updated_value", description: "New description")
        expect(described_class.find_by(key: "existing_key").description).to eq("New description")
      end

      it "preserves existing description if not provided" do
        described_class.set("existing_key", "updated_value")
        expect(described_class.find_by(key: "existing_key").description).to eq("Old description")
      end
    end

    it "returns the setting record" do
      result = described_class.set("new_key", "new_value")
      expect(result).to be_a(described_class)
      expect(result.key).to eq("new_key")
    end
  end

  describe ".rag_chunk_limit" do
    context "when not set" do
      it "returns the default value" do
        expect(described_class.rag_chunk_limit).to eq(10)
      end
    end

    context "when set" do
      before { create(:search_setting, key: "rag_chunk_limit", value: "20") }

      it "returns the stored value as integer" do
        expect(described_class.rag_chunk_limit).to eq(20)
      end
    end
  end

  describe ".rag_chunk_limit=" do
    it "stores the value" do
      described_class.rag_chunk_limit = 15
      expect(described_class.rag_chunk_limit).to eq(15)
    end

    it "converts to integer" do
      described_class.rag_chunk_limit = "25"
      expect(described_class.rag_chunk_limit).to eq(25)
    end

    it "sets an appropriate description" do
      described_class.rag_chunk_limit = 15
      setting = described_class.find_by(key: "rag_chunk_limit")
      expect(setting.description).to include("chunks")
    end
  end

  describe ".similar_questions_limit" do
    context "when not set" do
      it "returns the default value" do
        expect(described_class.similar_questions_limit).to eq(3)
      end
    end

    context "when set" do
      before { create(:search_setting, key: "similar_questions_limit", value: "5") }

      it "returns the stored value as integer" do
        expect(described_class.similar_questions_limit).to eq(5)
      end
    end
  end

  describe ".similar_questions_limit=" do
    it "stores the value" do
      described_class.similar_questions_limit = 5
      expect(described_class.similar_questions_limit).to eq(5)
    end

    it "converts to integer" do
      described_class.similar_questions_limit = "7"
      expect(described_class.similar_questions_limit).to eq(7)
    end
  end
end
