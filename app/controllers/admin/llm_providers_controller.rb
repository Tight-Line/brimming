# frozen_string_literal: true

module Admin
  class LlmProvidersController < BaseController
    before_action :set_llm_provider, only: [ :show, :edit, :update, :destroy, :activate, :set_default ]

    def index
      @llm_providers = LlmProvider.order(:name)
    end

    def show
    end

    def new
      @llm_provider = LlmProvider.new
      apply_defaults_from_provider_type if params[:provider_type].present?
    end

    def create
      @llm_provider = LlmProvider.new(llm_provider_params)

      if @llm_provider.save
        redirect_to admin_llm_provider_path(@llm_provider),
                    notice: "LLM provider created successfully."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
    end

    def update
      update_params = llm_provider_params_for_update

      # Preserve existing API key if field is left blank
      if update_params[:api_key].blank? && @llm_provider.api_key.present?
        update_params = update_params.except(:api_key)
      end

      if @llm_provider.update(update_params)
        redirect_to admin_llm_provider_path(@llm_provider),
                    notice: "LLM provider updated successfully."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      unless @llm_provider.can_delete?
        redirect_to admin_llm_providers_path,
                    alert: "Cannot delete an enabled LLM provider. Disable it first."
        return
      end

      @llm_provider.destroy!
      redirect_to admin_llm_providers_path,
                  notice: "LLM provider deleted.", status: :see_other
    end

    def activate
      @llm_provider.update!(enabled: !@llm_provider.enabled?)

      status = @llm_provider.enabled? ? "enabled" : "disabled"
      redirect_to admin_llm_providers_path,
                  notice: "#{@llm_provider.name} is now #{status}."
    end

    def set_default
      LlmProvider.transaction do
        LlmProvider.where(is_default: true).update_all(is_default: false)
        @llm_provider.update!(is_default: true, enabled: true)
      end

      redirect_to admin_llm_providers_path,
                  notice: "#{@llm_provider.name} is now the default LLM provider."
    end

    # API endpoint to detect Ollama and fetch available models
    def ollama_models
      endpoint = params[:endpoint]

      if endpoint.blank?
        # Auto-detect Ollama endpoint
        detected = OllamaDiscoveryService.detect_endpoint
        if detected
          models = OllamaDiscoveryService.fetch_models(detected)
          render json: { endpoint: detected, models: models }
        else
          render json: { error: "No Ollama instance found", endpoints_tried: OllamaDiscoveryService::DEFAULT_ENDPOINTS }, status: :not_found
        end
      else
        # Fetch models from specified endpoint
        if OllamaDiscoveryService.reachable?(endpoint)
          models = OllamaDiscoveryService.fetch_models(endpoint)
          render json: { endpoint: endpoint, models: models }
        else
          render json: { error: "Cannot connect to Ollama at #{endpoint}" }, status: :bad_request
        end
      end
    rescue OllamaDiscoveryService::Error => e
      render json: { error: e.message }, status: :bad_request
    end

    private

    def set_llm_provider
      @llm_provider = LlmProvider.find(params[:id])
    end

    def llm_provider_params
      params.require(:llm_provider).permit(
        :name, :provider_type, :api_key, :api_endpoint, :llm_model, :temperature, :max_tokens
      )
    end

    # For updates, provider_type and llm_model are immutable
    def llm_provider_params_for_update
      params.require(:llm_provider).permit(
        :name, :api_key, :api_endpoint, :temperature, :max_tokens
      )
    end

    def apply_defaults_from_provider_type
      model = LlmProvider.default_model_for(params[:provider_type])
      @llm_provider.assign_attributes(
        provider_type: params[:provider_type],
        llm_model: model,
        api_endpoint: LlmProvider::DEFAULT_ENDPOINTS[params[:provider_type]]
      )
    end
  end
end
