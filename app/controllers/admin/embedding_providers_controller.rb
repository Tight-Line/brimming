# frozen_string_literal: true

module Admin
  class EmbeddingProvidersController < BaseController
    before_action :set_embedding_provider, only: [ :show, :edit, :update, :destroy, :activate, :reindex ]

    def index
      @embedding_providers = EmbeddingProvider.order(:name)
    end

    def show
    end

    def new
      @embedding_provider = EmbeddingProvider.new
      apply_defaults_from_provider_type if params[:provider_type].present?
    end

    def create
      @embedding_provider = EmbeddingProvider.new(embedding_provider_params)

      if @embedding_provider.save
        redirect_to admin_embedding_provider_path(@embedding_provider),
                    notice: "Embedding provider created successfully."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
    end

    def update
      update_params = embedding_provider_params_for_update

      # Preserve existing API key if field is left blank
      if update_params[:api_key].blank? && @embedding_provider.api_key.present?
        update_params = update_params.except(:api_key)
      end

      if @embedding_provider.update(update_params)
        redirect_to admin_embedding_provider_path(@embedding_provider),
                    notice: "Embedding provider updated successfully."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      unless @embedding_provider.can_delete?
        redirect_to admin_embedding_providers_path,
                    alert: "Cannot delete an active embedding provider. Activate another provider first."
        return
      end

      @embedding_provider.destroy!
      redirect_to admin_embedding_providers_path,
                  notice: "Embedding provider deleted.", status: :see_other
    end

    def activate
      previous_provider = EmbeddingProvider.enabled.first

      EmbeddingProvider.transaction do
        EmbeddingProvider.where(enabled: true).update_all(enabled: false)
        @embedding_provider.update!(enabled: true)
      end

      # Trigger re-embedding if switching to a different provider
      if previous_provider.nil? || previous_provider.id != @embedding_provider.id
        RegenerateAllEmbeddingsJob.perform_later(@embedding_provider.id)
        embedded_count = Question.where.not(embedded_at: nil).count

        if embedded_count > 0
          redirect_to admin_embedding_providers_path,
                      notice: "#{@embedding_provider.name} is now active. Re-embedding #{embedded_count} questions in the background."
        else
          redirect_to admin_embedding_providers_path,
                      notice: "#{@embedding_provider.name} is now active. Embedding questions in the background."
        end
      else
        redirect_to admin_embedding_providers_path,
                    notice: "#{@embedding_provider.name} is now active."
      end
    end

    def reindex
      unless @embedding_provider.enabled?
        redirect_to admin_embedding_providers_path,
                    alert: "Can only reindex the active embedding provider."
        return
      end

      # Clear any pending embedding jobs from the queue
      embedding_queue = Sidekiq::Queue.new("embeddings")
      cleared_count = 0
      embedding_queue.each do |job|
        if job.klass == "GenerateQuestionEmbeddingJob"
          job.delete
          cleared_count += 1
        end
      end

      # Clear all existing chunks and reset embedded_at
      invalidated_count = Question.where.not(embedded_at: nil).update_all(embedded_at: nil)
      deleted_chunks = Chunk.delete_all

      # Queue fresh embedding jobs for all questions
      RegenerateAllEmbeddingsJob.perform_later(@embedding_provider.id)

      redirect_to admin_embedding_providers_path,
                  notice: "Reindexing started. Cleared #{cleared_count} pending jobs, #{invalidated_count} embeddings, and #{deleted_chunks} chunks. Re-embedding all questions."
    end

    private

    def set_embedding_provider
      @embedding_provider = EmbeddingProvider.find(params[:id])
    end

    def embedding_provider_params
      params.require(:embedding_provider).permit(
        :name, :provider_type, :api_key, :api_endpoint, :embedding_model, :similarity_threshold
      )
    end

    # For updates, provider_type and embedding_model are immutable
    def embedding_provider_params_for_update
      params.require(:embedding_provider).permit(
        :name, :api_key, :api_endpoint, :similarity_threshold
      )
    end

    def apply_defaults_from_provider_type
      defaults = EmbeddingProvider.default_config_for(params[:provider_type])
      @embedding_provider.assign_attributes(
        provider_type: params[:provider_type],
        embedding_model: defaults[:embedding_model],
        dimensions: defaults[:dimensions],
        api_endpoint: EmbeddingProvider::DEFAULT_ENDPOINTS[params[:provider_type]]
      )
    end
  end
end
