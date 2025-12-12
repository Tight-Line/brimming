# frozen_string_literal: true

module Admin
  class ReaderProvidersController < BaseController
    before_action :set_reader_provider, only: [ :edit, :update, :destroy, :activate ]

    def index
      @reader_providers = ReaderProvider.order(:name)
    end

    def new
      @reader_provider = ReaderProvider.new
      apply_defaults_from_provider_type if params[:provider_type].present?
    end

    def create
      @reader_provider = ReaderProvider.new(reader_provider_params)

      if @reader_provider.save
        redirect_to admin_reader_providers_path,
                    notice: "Reader provider created successfully."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
    end

    def update
      update_params = reader_provider_params_for_update

      # Preserve existing API key if field is left blank
      if update_params[:api_key].blank? && @reader_provider.api_key.present?
        update_params = update_params.except(:api_key)
      end

      if @reader_provider.update(update_params)
        redirect_to admin_reader_providers_path,
                    notice: "Reader provider updated successfully."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      unless @reader_provider.can_delete?
        redirect_to admin_reader_providers_path,
                    alert: "Cannot delete an active reader provider. Activate another provider first."
        return
      end

      @reader_provider.destroy!
      redirect_to admin_reader_providers_path,
                  notice: "Reader provider deleted.", status: :see_other
    end

    def activate
      ReaderProvider.transaction do
        ReaderProvider.where(enabled: true).update_all(enabled: false)
        @reader_provider.update!(enabled: true)
      end

      redirect_to admin_reader_providers_path,
                  notice: "#{@reader_provider.name} is now active."
    end

    private

    def set_reader_provider
      @reader_provider = ReaderProvider.find(params[:id])
    end

    def reader_provider_params
      params.require(:reader_provider).permit(
        :name, :provider_type, :api_key, :api_endpoint
      )
    end

    # For updates, provider_type is immutable
    def reader_provider_params_for_update
      params.require(:reader_provider).permit(
        :name, :api_key, :api_endpoint
      )
    end

    def apply_defaults_from_provider_type
      @reader_provider.assign_attributes(
        provider_type: params[:provider_type],
        api_endpoint: ReaderProvider::DEFAULT_ENDPOINTS[params[:provider_type]]
      )
    end
  end
end
