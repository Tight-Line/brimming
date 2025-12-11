# frozen_string_literal: true

module Admin
  class SearchSettingsController < BaseController
    def show
      @rag_chunk_limit = SearchSetting.rag_chunk_limit
      @similar_questions_limit = SearchSetting.similar_questions_limit
    end

    def update
      SearchSetting.rag_chunk_limit = params[:rag_chunk_limit].to_i
      SearchSetting.similar_questions_limit = params[:similar_questions_limit].to_i

      redirect_to admin_search_settings_path, notice: "Search settings updated successfully."
    end
  end
end
