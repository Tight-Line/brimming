# frozen_string_literal: true

class TagsController < ApplicationController
  before_action :set_space
  before_action :set_tag, only: [ :show, :destroy ]
  before_action :authenticate_user!, only: [ :create, :destroy ]

  # GET /spaces/:space_slug/tags
  def index
    @tags = @space.tags.alphabetical
  end

  # GET /spaces/:space_slug/tags/:slug
  def show
    @questions = policy_scope(@tag.questions)
                   .not_deleted
                   .recent
                   .includes(:user, :space, :tags)
                   .limit(100)
  end

  # GET /spaces/:space_slug/tags/search (JSON)
  def search
    tags = @space.tags.search(params[:q])

    render json: tags.map { |t|
      {
        slug: t.slug,
        name: t.name,
        questions_count: t.questions_count,
        description: t.description&.truncate(100)
      }
    }
  end

  # POST /spaces/:space_slug/tags
  def create
    @tag = @space.tags.build(tag_params)
    authorize @tag

    if @tag.save
      respond_to do |format|
        # TODO: i18n
        format.html { redirect_to tags_path(space_slug: @space.slug), notice: "Tag created successfully." }
        format.json { render json: tag_json(@tag), status: :created }
      end
    else
      respond_to do |format|
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: { errors: @tag.errors }, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /spaces/:space_slug/tags/:slug
  def destroy
    authorize @tag

    @tag.destroy!

    respond_to do |format|
      # TODO: i18n
      format.html { redirect_to tags_path(space_slug: @space.slug), notice: "Tag deleted.", status: :see_other }
      format.json { head :no_content }
    end
  end

  private

  def set_space
    @space = Space.find_by!(slug: params[:space_slug])
  end

  def set_tag
    @tag = @space.tags.find_by!(slug: params[:slug])
  end

  def tag_params
    params.require(:tag).permit(:name, :description)
  end

  def tag_json(tag)
    {
      id: tag.id,
      slug: tag.slug,
      name: tag.name,
      description: tag.description,
      questions_count: tag.questions_count
    }
  end
end
