# frozen_string_literal: true

require "rails_helper"

RSpec.describe RegenerateAllEmbeddingsJob do
  let(:space) { create(:space) }
  let(:user) { create(:user) }
  let!(:question1) { create(:question, space: space, user: user) }
  let!(:question2) { create(:question, space: space, user: user) }
  let!(:question3) { create(:question, space: space, user: user) }
  let(:mock_embedding) { Array.new(1536) { rand } }

  describe "#perform" do
    context "when switching providers" do
      let!(:old_provider) { create(:embedding_provider, :openai, enabled: false) }
      let!(:new_provider) { create(:embedding_provider, :cohere, :enabled) }

      before do
        # Simulate questions embedded by the old provider
        question1.update_columns(
          embedding: mock_embedding,
          embedded_at: 1.day.ago,
          embedding_provider_id: old_provider.id
        )
        question2.update_columns(
          embedding: mock_embedding,
          embedded_at: 1.day.ago,
          embedding_provider_id: old_provider.id
        )
        # question3 has no embedding
      end

      it "invalidates embeddings from the old provider" do
        described_class.new.perform(new_provider.id)

        expect(question1.reload.embedding).to be_nil
        expect(question1.embedding_provider_id).to be_nil
        expect(question1.embedded_at).to be_nil

        expect(question2.reload.embedding).to be_nil
      end

      it "queues embedding jobs for all questions" do
        expect {
          described_class.new.perform(new_provider.id)
        }.to have_enqueued_job(GenerateQuestionEmbeddingJob).exactly(3).times
      end

      it "preserves embeddings already from the new provider" do
        question1.update_columns(
          embedding: mock_embedding,
          embedded_at: 1.hour.ago,
          embedding_provider_id: new_provider.id
        )

        described_class.new.perform(new_provider.id)

        # question1 should still have its embedding
        expect(question1.reload.embedding).to be_present
        expect(question1.embedding_provider_id).to eq(new_provider.id)
      end
    end

    context "when provider is not enabled" do
      let!(:enabled_provider) { create(:embedding_provider, :openai, :enabled) }
      let!(:disabled_provider) { create(:embedding_provider, :cohere, enabled: false) }

      it "does nothing" do
        expect {
          described_class.new.perform(disabled_provider.id)
        }.not_to have_enqueued_job(GenerateQuestionEmbeddingJob)
      end
    end

    context "when provider does not exist" do
      it "does nothing" do
        expect {
          described_class.new.perform(999_999)
        }.not_to have_enqueued_job(GenerateQuestionEmbeddingJob)
      end
    end

    context "with deleted questions" do
      let!(:new_provider) { create(:embedding_provider, :openai, :enabled) }

      before do
        question2.update!(deleted_at: Time.current)
      end

      it "only queues jobs for non-deleted questions" do
        expect {
          described_class.new.perform(new_provider.id)
        }.to have_enqueued_job(GenerateQuestionEmbeddingJob).exactly(2).times
      end
    end
  end

  describe "queue configuration" do
    it "uses the embeddings queue" do
      expect(described_class.new.queue_name).to eq("embeddings")
    end
  end
end
