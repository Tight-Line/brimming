# frozen_string_literal: true

require "rails_helper"

RSpec.describe RegenerateAllEmbeddingsJob do
  let(:space) { create(:space) }
  let(:user) { create(:user) }
  let!(:question1) { create(:question, space: space, user: user) }
  let!(:question2) { create(:question, space: space, user: user) }
  let!(:question3) { create(:question, space: space, user: user) }
  let!(:article1) { create(:article, user: user) }
  let!(:article2) { create(:article, user: user) }
  let(:mock_embedding) { Array.new(1536) { rand } }

  describe "#perform" do
    context "when switching providers" do
      let!(:old_provider) { create(:embedding_provider, :openai, enabled: false) }
      let!(:new_provider) { create(:embedding_provider, :cohere, :enabled) }

      before do
        # Simulate questions with chunks from the old provider
        create(:chunk, :embedded, chunkable: question1, embedding_provider: old_provider)
        create(:chunk, :embedded, chunkable: question2, embedding_provider: old_provider)
        question1.update!(embedded_at: 1.day.ago)
        question2.update!(embedded_at: 1.day.ago)
        # question3 has no chunks
      end

      it "deletes chunks from the old provider" do
        expect(Chunk.count).to eq(2)

        described_class.new.perform(new_provider.id)

        expect(Chunk.where(embedding_provider: old_provider).count).to eq(0)
      end

      it "resets embedded_at for questions" do
        described_class.new.perform(new_provider.id)

        expect(question1.reload.embedded_at).to be_nil
        expect(question2.reload.embedded_at).to be_nil
      end

      it "queues embedding jobs for all questions" do
        expect {
          described_class.new.perform(new_provider.id)
        }.to have_enqueued_job(GenerateQuestionEmbeddingJob).exactly(3).times
      end

      it "queues embedding jobs for all articles" do
        expect {
          described_class.new.perform(new_provider.id)
        }.to have_enqueued_job(GenerateArticleEmbeddingJob).exactly(2).times
      end

      it "skips articles with chunks from the new provider" do
        # Add a chunk from the new provider to article1
        create(:chunk, :embedded, chunkable: article1, embedding_provider: new_provider)

        expect {
          described_class.new.perform(new_provider.id)
        }.to have_enqueued_job(GenerateArticleEmbeddingJob).exactly(1).times
      end

      it "preserves chunks already from the new provider" do
        # Add a chunk from the new provider to question1
        create(:chunk, :embedded, chunkable: question1, embedding_provider: new_provider)

        described_class.new.perform(new_provider.id)

        # question1 should still have its chunk from new provider
        expect(question1.chunks.where(embedding_provider: new_provider).count).to eq(1)
      end

      it "skips questions with chunks from the new provider" do
        # Add a chunk from the new provider to question1
        create(:chunk, :embedded, chunkable: question1, embedding_provider: new_provider)

        expect {
          described_class.new.perform(new_provider.id)
        }.to have_enqueued_job(GenerateQuestionEmbeddingJob).exactly(2).times
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
